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
out="$(run_hook "$ROOT/pravidla.md")"
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

echo "Limit 800 znaků"
python3 -I -c 'print("x" * 900)' >"$T/long.md" 2>/dev/null || printf 'x%.0s' $(seq 1 900) >"$T/long.md"
out="$(run_hook "$T/long.md")"
n="$(printf '%s' "$out" | grep -o 'x\{10,\}' | head -1 | tr -d '\n' | wc -c | tr -d ' ')"
[ "$n" -eq 800 ] && pass "hook ořízne na 800 ($n)" || fail "očekáváno 800 x, je $n"

echo "Soubor pravidla.md v repu respektuje limit"
chars="$(awk 'BEGIN{c=0} /<!--/{if($0!~/-->/)c=1;next} c&&/-->/{c=0;next} c{next} {printf "%s\n",$0}' "$ROOT/pravidla.md" | wc -c | tr -d ' ')"
[ "$chars" -le 800 ] && pass "pravidla.md: $chars ≤ 800" || fail "pravidla.md má $chars znaků (limit 800)"

echo "Verze v plugin.json a marketplace.json se shoduje"
v1="$(grep -o '"version": *"[^"]*"' "$ROOT/.claude-plugin/plugin.json" | head -1 | grep -o '[0-9][0-9.]*')"
v2="$(grep -o '"version": *"[^"]*"' "$ROOT/.claude-plugin/marketplace.json" | head -1 | grep -o '[0-9][0-9.]*')"
[ -n "$v1" ] && [ "$v1" = "$v2" ] && pass "verze $v1" || fail "verze: '$v1' vs '$v2'"

rm -rf "$T"
echo
[ "$fails" -eq 0 ] && echo "osobni: ALL PASS" || echo "osobni: $fails failed"
exit "$fails"
