# Animations

Two animations covering the first two stages of the method described in
[../ALGORITHM.md](../ALGORITHM.md). They are committed here rather than hosted
externally so that they form part of the archived, citable record of this
repository.

| File | Stage | Length |
|---|---|---|
| `stage1-tetrad-geometry.mp4` | 1 — ideal tetrad geometry | 2:07 |
| `stage2-torsion-buildup.mp4` | 2 — build-up in torsion space | 2:03 |
| `stage1-tetrad-geometry.webp` | stage 1 at 6× speed, for inline display | 0:23 |
| `stage2-torsion-buildup.webp` | excerpt of stage 2 at 4× speed, for inline display | 0:24 |

Both films are 1280×720, silent. GitHub does not play `.mp4` inline in Markdown
— follow the link and it opens in GitHub's file viewer, which has a player.

## Stage 1 — ideal tetrad geometry

Defines the two tetrad polarities, numbers the four guanosines of a tetrad,
introduces the pseudo-atoms `C1'` and `O4'` and the rotation about the N9–C1'
bond, and assembles the **pseudo-residue Q** — a whole tetrad treated as one
rigid unit. It closes by stacking three tetrads A, B and C with explicit
`translate z` and `rotation z` operations, which are the `rise` and `twist`
fields of the input file.

## Stage 2 — build-up in torsion space

Runs `multi-stage minimization in torsion angles space` from the bare
quadruplex core to the final structure, one fragment at a time: G2, T4–G5, G6,
G7, T8–T9–G10, G11, G12, T13–T14–G15, G16, G17. Each stage acquires a new
fragment, sets its torsion angles and the distance restraints for the
N-glycosidic bond, and minimises.

The `path` bar along the top highlights tokens as they are consumed, which is
the clearest available illustration of why `path` is a parameter of the method
and not bookkeeping: it *is* the order in the animation.

## Provenance and licence

Both films are original material produced by the authors of this repository.
They carry no third-party footage or figures, and they are covered by the
repository's licence — see [`../../LICENSE`](../../LICENSE).

## A note on vocabulary

The films were produced for **G4Composer**, the web application built on this
engine, so they use its interface labels. Two differ from the `.inp` keywords:

| In the films | In an `.inp` file |
|---|---|
| `Polarity`, values `A-;B-;C-` | `orient`, values `A-;B-;C-` — the same field |
| `G4minus` / `G4plus` | `orient` `-` / `+` |

The vocabulary is consistent underneath: `orient +` selects the `WH`
(Watson–Crick/Hoogsteen) hydrogen-bond direction and a tetrad library entry
whose name ends in `P`; `orient -` selects `HW` and an entry ending in `M` —
literally plus and minus. See [../INPUT-FORMAT.md](../INPUT-FORMAT.md#orient--glycosidic-orientation-per-tetrad-required).

The example shown in the films is `6pnk`, a three-tetrad structure written in
the `^` notation.

## Regenerating the derived files

The two `.mp4` files are the originals, unmodified. Both `.webp` files are
derived from them. Each ends with its last frame held for two seconds, so that
the loop does not cut off the result it has just built:

```bash
# Stage 1, whole film at 6× speed.
ffmpeg -i stage1-tetrad-geometry.mp4 \
    -vf "setpts=PTS/6,fps=10,scale=900:-1:flags=lanczos,tpad=stop_mode=clone:stop_duration=2" \
    -loop 0 -q:v 55 stage1-tetrad-geometry.webp

# Stage 2, from 0:29 to 1:58 at 4× speed. The opening seconds are the static
# quadruplex core, which the still at the top of the film already shows.
ffmpeg -ss 29 -to 118 -i stage2-torsion-buildup.mp4 \
    -vf "setpts=PTS/4,fps=10,scale=640:-1:flags=lanczos,tpad=stop_mode=clone:stop_duration=2" \
    -loop 0 -q:v 50 stage2-torsion-buildup.webp
```

Animated WebP is used rather than GIF because it is roughly seven times smaller
at equal dimensions and is not limited to 256 colours.
