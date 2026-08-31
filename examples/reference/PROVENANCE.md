# Reference outputs — provenance

Reference results for the inputs in `examples/`, with a record of the
environment that produced them. Use them to check that a local installation
behaves sanely before trusting it on real work.

Because CYANA and Xplor-NIH are supplied by each user rather than pinned by this
repository, results can differ slightly between installations. **Compare
`Etotal` and heavy-atom RMSD, not the files byte for byte** — each PDB carries a
`REMARK` line with the run's scratch path and timestamp, so even two runs on the
same machine differ textually.

Regenerate with:

```bash
tools/build.sh
tools/run.sh --outdir examples/reference \
    examples/6a-1hap_js12B.inp examples/pz74.inp examples/6pnk.inp
```

## Environment

| Component | Version / build |
|---|---|
| quadro engine | 14L |
| CYANA | 2.1 |
| Xplor-NIH | 2.39, Linux x86-64 |
| Base image | `ubuntu:22.04@sha256:2edbbc5dc405e9612ba3584ce95480277e3eb374407b5505fe26f17df77c7dbc` |
| CPU | Intel Core i7-12700K (x86-64) |
| Date | 2026-08-27 |

## Results

| Input | Output | Atoms | Residues | `Etotal` |
|---|---|---|---|---|
| `6a-1hap_js12B.inp` | `1hap_js12B_100.pdb` | 488 | 15 | −624.033 |
| `pz74.inp` | `pz74_mp_G14L_70.pdb` | 1313 | 41 | −901.663 |
| `6pnk.inp` | `6pnk.pdb` | 555 | 17 | −676.819 |

All runs completed with no `ERROR` lines in the engine output. Repeated runs on
this machine reproduced the first two energies exactly.

`6pnk.inp` was added later than the other two and its reference was produced on
2026-08-31, on the same machine and from the same Dockerfile, but in a
separately built image.
