# Changelog

All notable changes to quadro are recorded here. Versions follow the engine's
own naming (`14L`, …) rather than semantic versioning, because that is what the
`.inp` files, the published results and the image tags refer to.

Each released version is archived on Zenodo and carries its own DOI.

## [14L] — initial public release

- Standalone repository with the engine, its data libraries, a container recipe
  and documentation.
- CYANA and Xplor-NIH are supplied through BuildKit named build contexts rather
  than being part of the repository; neither may be redistributed. See
  `docs/THIRD-PARTY.md`.
- `docker/entrypoint.sh` gives a one-command interface
  (`docker run --rm -v "$PWD:/work" quadro14l:latest input.inp`) and stages
  inputs into the engine's working directory, which the engine requires because
  it resolves its data files relative to the current directory.

### Known issues
- **The process exit status is always 2**, successful or not: the AWK program is
  closed at line 859 of `engine/quadro14L.exe` and the trailing 24 lines of
  commented-out source are parsed by the shell instead. Cosmetic — judge success
  by whether a `.pdb` was produced.
- **Engine diagnostics are in Polish.** `docs/INPUT-FORMAT.md` carries a
  translated error table.
- `iteration_steps` checkpoints share a single build-up phase and differ only in
  the length of the final minimisation tail, so they explore less than their
  number suggests. Vary `iteration` across separate runs instead.
