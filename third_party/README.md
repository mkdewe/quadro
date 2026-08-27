# third_party/

These two directories are intentionally empty. They hold externally licensed
software that **cannot be redistributed** and is therefore excluded from this
repository by `.gitignore`:

```
third_party/cyana-2.1/          ← CYANA 2.1     (paid licence — cyana.org)
third_party/xplor-nih-2.39/     ← Xplor-NIH 2.39 (free for non-profit — nmr.cit.nih.gov/xplor-nih)
```

Unpack each distribution directly into the matching directory, then run:

```bash
../tools/check-third-party.sh
```

Full instructions, licence quotations and citation obligations:
[`../docs/THIRD-PARTY.md`](../docs/THIRD-PARTY.md).
