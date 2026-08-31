# How quadro builds a structure

quadro is a **generator and driver**, not a minimiser. It computes no energies
and moves no atoms itself. What it does is translate a topological description
of a G-quadruplex — which residues form which tetrad, in which orientation,
stacked with what rise and twist — into input decks for two established
structure-calculation programs, and run them in the right order.

The engine is a single AWK program (`engine/quadro14L.exe`, ~880 lines). The
`.exe` extension is the author's convention; it is a text script, and you can
read it.

```
 .inp ──▶ parse & validate ──▶ ideal tetrad geometry ──▶ CYANA deck ──▶ CYANA
                                  (tetrad.lib)                            │
                                                                          ▼
 .pdb ◀── xplor2pdb2.exe ◀── Xplor-NIH pass 2 ◀── Xplor-NIH pass 1 ◀── cyana2xplor.exe
```

---

## Stage 1 — ideal geometry from a library

`tetrad.lib`, `bp.lib` and `other_residues.lib` hold idealised coordinates and
torsion angles for G-tetrads, canonical base pairs and individual residues.
From `orient`, `rise` and `twist` the engine places each tetrad in space by
rotation and translation, producing a target geometry: a stack of tetrads with
the requested handedness and spacing.

Loops and any dot-bracket duplex regions in `structure` are not placed here —
they are grown in stage 2.

> 🎞 Animated: [`media/stage1-tetrad-geometry.mp4`](media/stage1-tetrad-geometry.mp4)
> — polarity, the pseudo-residue **Q**, and three tetrads stacked by explicit
> `translate z` / `rotation z` operations.

## Stage 2 — build-up in torsion space (CYANA)

This is where `path` earns its importance. The molecule is assembled **one
residue at a time, in `path` order**. After each residue is added, CYANA runs a
torsion-angle minimisation of `iteration` steps against the accumulated angle
restraints:

```awk
printf "minimize %d\n", iteration > FO_INIT     # once per build-up stage
```

> 🎞 Animated: [`media/stage2-torsion-buildup.mp4`](media/stage2-torsion-buildup.mp4)
> — the whole build-up, stage by stage, with the `path` bar highlighting each
> token as its residue is added.

Working in torsion space rather than Cartesian space is what makes this
tractable: bond lengths and angles stay at ideal values by construction, so only
the rotatable degrees of freedom are searched. A final CYANA pass closes the
stage.

Two consequences worth stating plainly, because they drive how the tool should
be used:

- **`path` is a parameter of the method, not bookkeeping.** The same topology
  built in a different residue order traverses a different sequence of
  intermediate structures and lands somewhere else.
- **`iteration` controls the starting point, not the answer.** It decides how
  well-relaxed a structure the Cartesian refinement receives. The 2000 Xplor
  steps in stage 3 run regardless. Raising it is therefore not monotonically
  better: a deeper build-up improves some structures and degrades others,
  because it changes which local minimum the refinement starts from.

The natural way to exploit that is to run several depths and keep the lowest
`Etotal`, rather than to search for one universally good depth.

## Stage 3 — Cartesian refinement (Xplor-NIH)

`cyana2xplor.exe` converts the CYANA result into an Xplor-NIH structure/topology
pair, and the engine emits a two-pass refinement deck against the
`dna-rna-allatom` force field.

**Pass 1 — tetrad core frozen.** The atoms that define tetrad geometry
(`C1′`, `N9`, `O6`, `N1`, `N3`, `N7`) are held fixed on every tetrad residue,
so loops and backbone relax around a core that cannot drift:

```
constraints fix=((name C1' or name N9 or name O6 or name N1 or name N3 or name N7)
                 and (resi … all tetrad residues …)) end
flags exclude * include bond angl cdih impr vdw noe elec plan end
minimize powell nstep=1000 nprint=100 end
```

**Pass 2 — everything released.** All constraints are lifted
(`constraints fix=(not ALL)`) and the tetrads are instead held together by
restraints rather than by being frozen: planarity restraints at weight 20, the
dihedral set, and an NOE-style hydrogen-bond network (square potential,
`scale 50`, `ceiling 1000`) standing in for the Hoogsteen bonds. A second
`nstep=1000` Powell minimisation follows.

Both passes are fixed at 1000 steps and are not configurable from the `.inp`.

## Stage 4 — output

`xplor2pdb2.exe` renames and renumbers the refined coordinates into the final
`<name>.pdb`, and the Xplor energy report is written to `<name>_energy.txt`.
`Etotal` from that file is the ranking figure when comparing several models of
the same sequence.

---

## The alternative engine

`alternatywa<version>.exe` is not a second engine but a wrapper. It derives a
mirrored copy of the input and invokes the ordinary engine twice: once on the
original, once on the mirrored copy. Four fields are inverted:

| Field | Transformation | Example |
|---|---|---|
| `orient` | every `+` ↔ `-` | `A+;B-` → `A-;B+` |
| `rise` | sign flipped | `3.4` → `-3.4` |
| `twist` | sign flipped | `19` → `-19` |
| `path` | positions `2` ↔ `4` in every token | `A1;B1;B4;A4;A3;B3;B2;A2` → `A1;B1;B2;A2;A3;B3;B4;A4` |
| `name` | suffixed | `foo` → `foo_alt` |

Inverting the stacking direction, the twist and the hydrogen-bond directionality
together, and reordering the residues within each tetrad accordingly, yields the
opposite-handed arrangement of the same residues.

The rationale is that a topology specified through `orient`, `rise`, `twist` and
`path` does not determine the handedness the molecule adopts. The opposite
reading gives a sterically plausible structure differing only in energy, so the
ambiguity is not resolvable by inspection of the model. Constructing both and
comparing `Etotal` resolves it by calculation.

One invocation therefore yields two structures with identical atom counts and
different coordinates:

```bash
tools/run.sh --alt --outdir out examples/6a-1hap_js12B.inp
```

```
out/1hap_js12B_100.pdb            Etotal = -624.033   input as written
out/1hap_js12B_100_alt.pdb        Etotal = -623.782   mirror image
out/1hap_js12B_100_energy.txt
out/1hap_js12B_100_alt_energy.txt
```

The margin here is 0.25, which does not discriminate between the two
arrangements for this sequence. A large separation, by contrast, rules out the
opposite reading of the topology. (Xplor-NIH does not label the units in
`<name>_energy.txt`; treat `Etotal` as a relative figure for ranking models of
the same sequence, not as an absolute quantity.)

---

## Computational cost

A typical 15–25 nt structure takes on the order of a minute per pass on one
core, dominated by CYANA's build-up: cost grows with the number of build-up
stages (≈ the length of `path`) multiplied by `iteration`. The two Xplor passes
are a fixed cost that does not depend on any `.inp` setting.

Nothing in the pipeline is parallelised internally. Throughput comes from
running independent inputs concurrently in separate containers.
