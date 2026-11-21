# honzapowers-osobni (šablona)

Osobní vrstva k pluginu [honzapowers](https://github.com/MedniLedved/honzapowers): tvoje vlastní krátká pravidla, která se vloží na začátku každé session. Plugin `honzapowers` zůstává obecný, tvoje osobní věci žijí ve tvém soukromém repu.

## Jak ji použít
1. Na GitHubu klikni na **Use this template** → **Create a new repository**. Nastav **Private**.
2. V novém repu otevři `pravidla.md`, smaž komentář a napiš vlastní pravidla (jedno na řádek). Limit je **800 znaků** mimo komentáře `<!-- … -->` (komentář může být i na řádku s pravidlem, text mimo něj se zachová). V `.claude-plugin/plugin.json` a `marketplace.json` přepiš jméno autora na své.
3. Na claude.ai: Customize → Plugins → Add → **Add marketplace** → tvoje nové repo, zapni **Sync automatically** a povol `honzapowers-osobni`.
4. Nové session pak začnou blokem `Personal rules (honzapowers-osobni):` s tvými pravidly.

Dokud je v `pravidla.md` jen komentář nebo nic, plugin nic nevloží.

## Co patří do pravidel
Jen to, co platí napříč všemi tvými projekty (např. výběr modelu, styl odpovědí). Projektová pravidla patří do `CLAUDE.md` / `AGENTS.md` projektu a mají přednost.

## Vývoj
```bash
bash tests/run-tests.sh
```

```bash
claude plugin validate --strict .
```

Hook je bash skript spouštěný přes `hooks/run-hook.cmd`, takže funguje i na Windows s Git Bash. Je jen pro čtení, nepoužívá síť a vždy končí s kódem 0.
