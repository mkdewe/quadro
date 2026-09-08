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
| quadro engine | 14M |
| CYANA | 2.1 |
| Xplor-NIH | 2.39, Linux x86-64 |
| Base image | `ubuntu:22.04@sha256:2edbbc5dc405e9612ba3584ce95480277e3eb374407b5505fe26f17df77c7dbc` |
| CPU | Intel Core i7-12700K (x86-64) |
| Date | 2026-09-08 |

## Results

Each input yields two structures, because the mirror pass is part of an ordinary
run: the topology as written, and the same residues in the opposite-handed
stack.

| Input | Output | Atoms | Residues | `Etotal` |
|---|---|---|---|---|
| `6a-1hap_js12B.inp` | `1hap_js12B_100.pdb` | 488 | 15 | −620.281 |
| | `1hap_js12B_100_alt.pdb` | 488 | 15 | **−629.866** |
| `pz74.inp` | `pz74_mp_70.pdb` | 1313 | 41 | −906.937 |
| | `pz74_mp_70_alt.pdb` | 1313 | 41 | **−945.249** |
| `6pnk.inp` | `6pnk.pdb` | 555 | 17 | −665.030 |
| | `6pnk_alt.pdb` | 555 | 17 | **−666.835** |

All six runs completed with no `ERROR` lines in the engine output. The lower
`Etotal` of each pair is shown in bold; it is the mirrored reading in all three
cases, which is a property of these particular inputs and not a general result.

The margins are worth reading carefully. For `6pnk` the two readings are
1.8 apart on a total near 666, which does not discriminate between them. For
`pz74` the separation is 38, which does.

## Comparison with 14L

The same three inputs under 14L gave −624.033, −901.663 and −676.819. Atom and
residue counts are identical, so the two engines build the same molecules; the
energies are not, and were not expected to be.

Two changes in the CYANA stage account for it. 14L re-read the accumulated angle
file (`read ang Q<n>`) immediately before the closing minimisation and 14M does
not, and 14L ran that closing minimisation for `iteration` steps where 14M fixes
it at 100. Neither engine is a recomputation of the other: they hand Xplor-NIH
different starting structures.
