#!/usr/bin/env bash
# Testy hooku honzapowers-osobni: prázdný vzor, vložení, limit 800 znaků.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fails=0
pass() { echo "  [PASS] $1"; }
fail() { echo "  [FAIL] $1"; fails=$((fails + 1)); }

run_hook() { # $1 = soubor pravidla.md; kopie pluginu v tmp
  local d; d="$(mktemp -d)"
  mkdir -p "$d/hooks"
  cp "$ROOT/hooks/session-start" "$d/hooks/"
  cp "$1" "$d/pravidla.md"
  bash "$d/hooks/session-start" </dev/null
  rm -rf "$d"
}

T="$(mktemp -d)"

echo "Vzor ze šablony (jen komentář) nevloží nic"
printf '<!--\nvzor jen s komentářem\n-->\n' >"$T/vzor.md"
out="$(run_hook "$T/vzor.md")"
[ -z "$out" ] && pass "prázdný vzor ⇒ žádný výstup" || fail "vzor vložil: $out"

echo "Prázdný soubor nevloží nic"
: >"$T/empty.md"
out="$(run_hook "$T/empty.md")"
[ -z "$out" ] && pass "prázdný soubor ⇒ žádný výstup" || fail "prázdný soubor vložil: $out"

echo "Text se vloží pod nadpisem, komentář ne"
printf '<!-- skryto -->\nM1 test pravidlo\n<!--\nvíceřádkový\n-->\nDruhé "pravidlo"\n' >"$T/ok.md"
out="$(run_hook "$T/ok.md")"
case "$out" in *'Personal rules (honzapowers-osobni):'*) pass "nadpis" ;; *) fail "chybí nadpis: $out" ;; esac
case "$out" in *'M1 test pravidlo'*) pass "první řádek" ;; *) fail "chybí řádek" ;; esac
case "$out" in *skryto* | *víceřádkový*) fail "komentář prosákl" ;; *) pass "komentáře ignorovány" ;; esac
case "$out" in *'Druhé \"pravidlo\"'*) pass "uvozovky escapované" ;; *) fail "escapování: $out" ;; esac
if command -v python3 >/dev/null 2>&1; then
  printf '%s' "$out" | python3 -I -c 'import json,sys;json.load(sys.stdin)' && pass "platný JSON" || fail "neplatný JSON"
fi

echo "Komentář na řádku s pravidlem: pravidlo zůstane"
printf 'M1 pravidlo <!-- pozn --> dál\n<!-- celý řádek -->\nM2 před <!-- začátek\nskryto\nkonec --> za\n' >"$T/inline.md"
out="$(run_hook "$T/inline.md")"
case "$out" in *'M1 pravidlo  dál'*) pass "text před i za komentářem" ;; *) fail "inline komentář: $out" ;; esac
case "$out" in *'M2 před \n za'*) pass "komentář přes řádky uprostřed řádku" ;; *) fail "víceřádkový inline: $out" ;; esac
case "$out" in *pozn* | *skryto* | *'celý řádek'*) fail "komentář prosákl" ;; *) pass "text komentáře nevložen" ;; esac

echo "Nezavřený komentář skryje zbytek souboru, hook skončí kódem 0"
printf 'M1 viditelné\n<!-- nezavřeno\nM2 skryté\n' >"$T/open.md"
out="$(run_hook "$T/open.md")"
case "$out" in *'M1 viditelné'*) pass "text před komentářem" ;; *) fail "chybí M1: $out" ;; esac
case "$out" in *'M2 skryté'*) fail "skryté prosáklo" ;; *) pass "zbytek za nezavřeným komentářem skryt" ;; esac

echo "CRLF soubor"
printf 'M1 crlf\r\n<!-- k -->\r\nM2 crlf\r\n' >"$T/crlf.md"
out="$(run_hook "$T/crlf.md")"
case "$out" in *'\r'*) fail "CR zůstalo ve výstupu" ;; *) pass "CR odstraněno" ;; esac
case "$out" in *'M1 crlf\nM2 crlf'*) pass "řádky spojeny přes \\n" ;; *) fail "CRLF: $out" ;; esac

echo "Chybějící pravidla.md: žádný výstup, kód 0"
d="$(mktemp -d)"; mkdir -p "$d/hooks"; cp "$ROOT/hooks/session-start" "$d/hooks/"
out="$(bash "$d/hooks/session-start" </dev/null)"; rc=$?
[ -z "$out" ] && [ "$rc" -eq 0 ] && pass "bez souboru: prázdno, kód 0" || fail "bez souboru: rc=$rc out=$out"
rm -rf "$d"

echo "Limit 800 znaků (ASCII)"
printf 'x%.0s' $(seq 1 900) >"$T/long.md"
out="$(run_hook "$T/long.md")"
n="$(printf '%s' "$out" | grep -o 'x\{10,\}' | head -1 | tr -d '\n' | wc -c | tr -d ' ')"
[ "$n" -eq 800 ] && pass "ořez na 800 ($n)" || fail "očekáváno 800 x, je $n"

echo "Limit 800 znaků (čeština, UTF-8)"
python3 -I -c 'print("a" + "ž" * 900)' >"$T/cz.md"
out="$(run_hook "$T/cz.md")"
chars="$(printf '%s' "$out" | python3 -I -c 'import sys,json;print(len(json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"].split("\n",1)[1]))' 2>&1)"
[ "$chars" = "800" ] && pass "800 znaků, platné UTF-8 a JSON" || fail "čeština: $chars"

echo "Bajtový locale: ořez nepřeřízne znak"
out="$(HONZAPOWERS_OSOBNI_LOCALE=C run_hook "$T/cz.md")"
printf '%s' "$out" | python3 -I -c 'import sys,json;b=sys.stdin.buffer.read();json.loads(b.decode("utf-8"))' 2>/dev/null \
  && pass "výstup je platné UTF-8 i v bajtovém locale" || fail "rozbité UTF-8 v bajtovém locale"

echo "Skutečné pravidla.md v repu se vejde do limitu (hook je neořízne)"
d="$(mktemp -d)"; mkdir -p "$d/hooks"
sed 's/^MAX_CHARS=800/MAX_CHARS=100000/' "$ROOT/hooks/session-start" >"$d/hooks/session-start"
cp "$ROOT/pravidla.md" "$d/pravidla.md"
out="$(bash "$d/hooks/session-start" </dev/null)"
if [ -z "$out" ]; then pass "pravidla.md bez textu (vzor)"; else
  n="$(printf '%s' "$out" | python3 -I -c 'import sys,json;print(len(json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"].split("\n",1)[1]))' 2>/dev/null)"
  [ -n "$n" ] && [ "$n" -le 800 ] && pass "pravidla.md: $n ≤ 800 znaků" || fail "pravidla.md má '$n' znaků (limit 800)"
fi
rm -rf "$d"

echo "Verze v plugin.json a marketplace.json se shoduje"
v1="$(grep -o '"version": *"[^"]*"' "$ROOT/.claude-plugin/plugin.json" | head -1 | grep -o '[0-9][0-9.]*')"
v2="$(grep -o '"version": *"[^"]*"' "$ROOT/.claude-plugin/marketplace.json" | head -1 | grep -o '[0-9][0-9.]*')"
[ -n "$v1" ] && [ "$v1" = "$v2" ] && pass "verze $v1" || fail "verze: '$v1' vs '$v2'"

rm -rf "$T"
echo
[ "$fails" -eq 0 ] && echo "osobni: ALL PASS" || echo "osobni: $fails failed"
exit "$fails"
