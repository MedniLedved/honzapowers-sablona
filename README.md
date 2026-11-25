# honzapowers-osobni (šablona)

Osobní vrstva k pluginu [honzapowers](https://github.com/MedniLedved/honzapowers): tvoje vlastní krátká pravidla, která se vloží na začátku každé session. Plugin `honzapowers` zůstává obecný, tvoje osobní věci žijí ve tvém soukromém repu.

## Jak ji použít
1. Na GitHubu klikni na **Use this template** → **Create a new repository**. Nastav **Private**.
2. V novém repu otevři `pravidla.md`, smaž komentář a napiš vlastní pravidla (jedno na řádek). Limit je **800 znaků** mimo komentáře `<!-- … -->` (komentář může být i na řádku s pravidlem, text mimo něj se zachová). V `.claude-plugin/plugin.json` a `marketplace.json` nahraď `TVOJE-JMENO` svým jménem nebo přezdívkou.
3. Na claude.ai: Customize → Plugins → Add → **Add marketplace** → tvoje nové repo, zapni **Sync automatically** a povol `honzapowers-osobni`. Repo je soukromé, takže claude.ai k němu potřebuje přístup: musíš mít na claude.ai připojený GitHub, jinak přidání marketplace selže.
4. Nové session pak začnou blokem `Personal rules (honzapowers-osobni):` s tvými pravidly.

Dokud je v `pravidla.md` jen komentář nebo nic, plugin nic nevloží.

Testovací workflow v `.github/workflows/` běží jen ve zdrojové šabloně. Ve tvém repu se joby přeskočí, takže ti nespotřebují minuty GitHub Actions. Můžeš ho i smazat.

## Ochrana větve `main` ve tvém repu
Hook z tvého repa běží u tebe v každé session, proto má smysl `main` chránit: GitHub → Settings → Rules → Rulesets → New branch ruleset, cíl `main`, **Enforcement status: Active** (nový ruleset je jinak vypnutý), zapni **Restrict deletions** a **Block force pushes**, případně **Require a pull request before merging**. **Povinné kontroly (required status checks) nepřidávej:** joby z `test.yml` se ve tvém repu přeskočí, takže by nic nehlídaly, a kontrola pojmenovaná podle varianty matice by zůstala čekat a blokovala by každý PR.

Na bezplatném účtu rulesety v soukromém repu nejsou k dispozici (jen ve veřejném nebo na placeném plánu). Pak ochrana není, takže si na `main` nepushuj s `--force`.

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

## Licence
MIT, viz [`LICENSE`](LICENSE).
