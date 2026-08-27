# Examples

| File | What it demonstrates |
|---|---|
| `6a-1hap_js12B.inp` | Unimolecular antiparallel DNA G-quadruplex, two tetrads, labelled `structure` notation, `chi` fixing *syn* residues. |
| `pz74.inp` | Caret `^` notation combined with a dot-bracket duplex — a G-quadruplex embedded in a longer paired construct. |
| `pz74-rm0.inp` | Same as `pz74.inp` with `rm_level 0`, so all CYANA/Xplor intermediates are kept. Use this one when diagnosing a failure. |

Run one:

```bash
tools/run.sh --outdir out examples/6a-1hap_js12B.inp
```

The `.inp` format is documented in [`../docs/INPUT-FORMAT.md`](../docs/INPUT-FORMAT.md).

## `reference/`

Reference outputs for the inputs above, produced with the CYANA and Xplor-NIH
builds recorded in `reference/PROVENANCE.md`. They let a reader check a local
installation without having to judge a structure by eye, and let a reviewer
verify the published results without owning a CYANA licence.

Because CYANA and Xplor-NIH are supplied by each user rather than pinned by this
repository, small numerical differences across builds are expected. Compare
`Etotal` and heavy-atom RMSD rather than diffing the PDB files byte for byte.
