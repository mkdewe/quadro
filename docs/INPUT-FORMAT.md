# The `.inp` input file

One plain-text file describes one G-quadruplex to build. Each line is
`keyword value` — whitespace-separated, one keyword per line, order irrelevant.
Unknown lines are ignored, so `#`-prefixed comments are safe in practice.

The value **must not contain spaces**: the parser reads `$2`, so `path A1; B1`
silently loses everything after the first space. Use `A1;B1`.

A minimal, complete example — a parallel unimolecular DNA G-quadruplex
(PDB 1HAP-like), `examples/6a-1hap_js12B.inp`:

```
name        1hap_js12B_100
sequence    ggttggtgtggttgg
structure   AB..BA...AB..BA
chi         S...S....S...S.
orient      A+;B-
rise        3.4
twist       19
path        A1;B1;B4;A4;A3;B3;B2;A2
test        y
rm_level    5
iteration   100
```

---

## Keywords

### `name` — output base name
Every result file is named after it: `<name>.pdb`, `<name>_energy.txt`.
Defaults to `quadro7_test` if omitted. Keep it filesystem-safe.

### `sequence` — the nucleotide sequence *(required)*
**Case encodes the sugar, not the base.**

| Characters | Meaning |
|---|---|
| `A C G U` (uppercase) | ribonucleotides — RNA |
| `a c g t` (lowercase) | deoxyribonucleotides — DNA |

Mixed case is allowed and gives a chimeric RNA/DNA molecule; the engine reports
the RNA fraction. Anything else is rejected with `ERROR 2`.

> Note the asymmetry, which is a common source of confusion: **uppercase `T` and
> lowercase `u` are not valid.** Uracil is always uppercase `U`, thymine always
> lowercase `t`.

### `structure` — which residues form tetrads *(required)*
Same length as `sequence`, or `ERROR 4`. Two notations are accepted, chosen
automatically by whether a `^` appears anywhere in the field:

**(a) Labelled notation** — no `^` present. Uppercase letters `A`, `B`, `C`, …
mark residues that belong to a tetrad; the letter names the **column** (the
strand-like stack) the residue sits in. Everything else is a non-tetrad residue:

- `.` — unpaired (loop, overhang)
- `(` `)` `[` `]` `{` `}` `<` `>` — canonical base pairs, in the usual
  dot-bracket sense; used for duplex stems flanking or joining the quadruplex.

**(b) Caret notation** — at least one `^` present. Every `^` marks a tetrad
residue and the column assignment is taken entirely from `path`. Convenient for
large structures where letter bookkeeping is error-prone. `examples/pz74.inp`
uses this together with a dot-bracket duplex:

```
structure   (((((((((((^^.^^.((...))^^.^^.)))))))))))
```

Constraints, in the order the engine checks them:
- the number of tetrad-marked residues must be a multiple of 4 (`ERROR 104`)
- it must equal the number of entries in `path` (`ERROR 105`)
- every tetrad residue must be `G`, `g`, `U` or `u` (`ERROR 5`)
- brackets must be balanced and pair with a valid partner (`ERROR 106`)

### `path` — the build-up order *(required)*
Semicolon-separated list of `<column><position>` tokens, exactly
`4 × number_of_tetrads` of them (`ERROR 14`).

Each token names one tetrad residue: the letter is its column (`A`, `B`, …), the
digit its index within that column counted along the sequence. Consecutive
groups of four form one tetrad, and each such group must resolve to `GGGG`,
`UUUU` or `TTTT` (`ERROR 15`).

**`path` order is the build-up order**, and it is the single most consequential
field in the file: the engine adds residues to the growing molecule in exactly
this sequence, running a CYANA minimisation after each one. A different `path`
over the same topology is a different calculation with a different result. See
[ALGORITHM.md](ALGORITHM.md).

### `orient` — glycosidic orientation per tetrad *(required)*
Semicolon-separated, **one entry per tetrad**, in tetrad order (`ERROR 11`).
Each entry is a column letter followed by `+` or `-`:

- `+` → Watson–Crick/Hoogsteen (`WH`) hydrogen-bond directionality
- `-` → Hoogsteen/Watson–Crick (`HW`)

The letter must match the tetrad's ordinal position (`A` for the first, `B` for
the second, …) or you get `ERROR 12`; the sign must be `+` or `-` (`ERROR 13`).

### `chi` — glycosidic torsion, per residue *(optional)*
Same length as `sequence` (`ERROR 17`). One character per residue, from `.AaSs`
(`ERROR 18`):

| Char | Meaning |
|---|---|
| `S` / `s` | *syn* |
| `A` / `a` | *anti* |
| `.` | let the engine decide |

Uppercase fixes the value; lowercase supplies it as a starting point.

> ⚠ `N` is **not** valid here despite being valid in `sugar`. Passing it yields
> `ERROR 18`.

### `sugar` — sugar pucker, per residue *(optional)*
Same length as `sequence` (`ERROR 19`). One character per residue, from `.NnSs`
(`ERROR 20`):

| Char | Meaning |
|---|---|
| `N` / `n` | North — C3′-endo, the RNA-like pucker |
| `S` / `s` | South — C2′-endo, the DNA-like pucker |
| `.` | default for the residue's sugar type |

Omit the line entirely to accept the defaults.

### `rise` — helical rise, Å *(optional, default 3.4)*
One value, or one per tetrad-to-tetrad step, semicolon-separated:
`rise 3.4;3.3` for a three-tetrad stack.

### `twist` — helical twist, degrees *(optional, default 29)*
Same multi-step syntax as `rise`: `twist 19;29`. Typical values are ≈30° for
parallel and ≈15–20° for antiparallel stacks.

### `iteration` — CYANA minimisation depth *(optional, default 50)*
Number of CYANA minimisation steps run **at every build-up stage**. Must be
≥ 10 (`ERROR 25`).

More is not monotonically better. `iteration` decides how good a starting
structure the Cartesian refinement receives, not how good the final answer is —
2000 hard-wired Xplor-NIH steps follow regardless. See [ALGORITHM.md](ALGORITHM.md).

### `iteration_steps` — checkpoint ladder *(optional)*
Comma-separated list, e.g. `iteration_steps 30,50,70,100`. Each value ≥ 10
(`ERROR 25`). Produces one refined structure per checkpoint from a **single**
run.

> Note the shared build-up: all checkpoints in one `iteration_steps` run come
> from the same build-up phase and differ only in the length of the final
> minimisation tail, so they explore less than their number suggests. To vary
> the build-up itself, run the engine repeatedly with different `iteration`
> values instead.

`iteration` and `iteration_steps` both set the same internal ladder; whichever
line comes last in the file wins.

### `my_angles` — extra torsion-angle restraints *(optional)*
Path to a CYANA angle-restraint file. The name **must** end in `.cya`
(`ERROR 16`).

### `test` — verbose mode *(optional, default `n`)*
`y` keeps the engine chatty and preserves diagnostic output. `n` for production.

### `rm_level` — intermediate-file cleanup *(optional, default 5)*
Controls only how much of the CYANA/Xplor scratch is deleted afterwards. It has
**no effect on the resulting geometry or energy**.

| Level | Effect |
|---|---|
| `0` | keep everything — use this when debugging a failed run |
| `5` | remove all intermediate files |

---

## Output

For a run with `name FOO`:

| File | Contents |
|---|---|
| `FOO.pdb` | the refined 3D structure |
| `FOO_energy.txt` | final Xplor-NIH energy terms, including `Etotal` |
| `FOO.runlog` | full engine output (written by the container entrypoint) |

With `iteration_steps`, one `<name>_<K>.pdb` / `<name>_<K>_energy.txt` pair is
written per checkpoint `K`.

With the alternative engine (`--alt`) you get **two** pairs: `FOO.pdb` for the
input as written, and `FOO_alt.pdb` for the mirrored arrangement — the same
residues stacked with the opposite handedness. Keep whichever has the lower
`Etotal`; see [ALGORITHM.md](ALGORITHM.md#the-alternative-engine).

`Etotal` is the figure to compare when ranking several models of the same
sequence — lower is better.

---

## Error codes

All engine diagnostics are printed as `ERROR <n> : <message>`. **The messages
are in Polish**; the table below is the translation.

| Code | Meaning |
|---|---|
| 1 | `sequence` missing |
| 2 | invalid residue in `sequence` — see the alphabet above |
| 3 | `structure` missing |
| 4 | `sequence` and `structure` differ in length |
| 5 | a tetrad residue is not `G`/`g`/`U`/`u` |
| 11, 13 | malformed `orient` |
| 12 | `orient` letter does not match the tetrad's position |
| 14 | `path` length ≠ 4 × number of tetrads |
| 15 | a group of four in `path` does not spell `GGGG`/`UUUU`/`TTTT` |
| 16 | `my_angles` does not end in `.cya` |
| 17 | `chi` length ≠ `sequence` length |
| 18 | invalid character in `chi` (allowed: `.AaSs`) |
| 19 | `sugar` length ≠ `sequence` length |
| 20 | invalid character in `sugar` (allowed: `.NnSs`) |
| 25 | `iteration` / `iteration_steps` value below 10 |
| 102 | `sequence` failed the residue-count cross-check |
| 104 | tetrad-residue count is not a multiple of 4, or bad `structure` character |
| 105 | `structure` and `path` disagree |
| 106 | unbalanced or invalid base pair in `structure` |

A non-zero **process** exit status is *not* an error indicator in 14L: the AWK
program is closed at line 859 of `engine/quadro14L.exe` and the trailing 24
lines of commented-out source are parsed by the shell instead, so the engine
exits 2 on every run, successful or not. Judge success by whether a `.pdb` was
produced.
