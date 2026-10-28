# CBC Options

Derived from: cbc-mp-options.md

Source: `raw/cbc-mp-options.md` (`https://dev.ampl.com/solvers/cbc/options.html`), current
as of 2026-10-28. CBC is reached through an MP-based driver (`cbc`, 263 option entries).
**This is a curated subset of commonly-tuned options**; see the raw source for the full
list.

## Setting options

```ampl
option solver cbc;
option cbc_options 'outlev=1 timelim=300 ratioGap=0.01';
solve;
```

The option list mixes two kinds of names:

- **MP names** with a `prefix:name` form (`lim:time`, `cut:gomorycuts`, `mip:rins`,
  `pre:presolve`), with CBC's own name as alias in parentheses (`gomoryCuts`, `Rins`).
- **CBC's native numeric parameters** under `double:` and `int:` (`double:ratioGap`,
  `int:maxNodes`); the part after the colon also works alone (`ratioGap=0.01`).

CBC has **no** `mip:gap`/`mipgap` option: use `double:ratioGap` (relative) and
`double:allowableGap` (absolute). General mechanics (`mp_options`, option files,
querying values): `../mp-library/feature-and-solver-options-guide.md`.

What CBC handles: LP and MILP only — no QP/MIQP, quadratic or nonlinear terms are
approximated piecewise-linearly by MP (`../core-language/13-solver-selection-guide.md`).
In the MP feature table CBC supports model export, warm start, basis I/O and (emulated)
multiple objectives, but not IIS, feasibility relaxation, sensitivity, MIP-gap return or
solution export.

## Verbosity

`tech:outlev` (`outlev`), 0 (default) to 4. `int:verbose` and `tech:messages` give more
CBC-specific output control.

## Autotuner

**None.** The option list has no tuning family; `int:strategy` (default 1) switches on
groups of features as a coarse preset.

## MIP stopping criteria

| Option | Effect |
|---|---|
| `lim:time` (`timelim`) | Time limit in seconds (default no limit); `double:seconds` is CBC's own |
| `double:ratioGap` (`ratioGap`) | Stop when the gap is below this fraction of the larger of bound and incumbent (default 0) |
| `double:allowableGap` (`allowableGap`) | Absolute gap (default 0) |
| `int:maxNodes` (`maxNodes`) | Max. nodes |
| `int:maxSolutions` (`maxSolutions`) | Max. feasible solutions (default -1 = no limit) |
| `double:cutoff` (`cutoff`) | Bound on the objective value for all solutions |
| `double:increment` (`increment`) | Each new incumbent must improve by at least this (default 1e-5) |

```ampl
option cbc_options 'timelim=600 ratioGap=0.005 maxNodes=200000';
```

## Variable/branch selection and heuristics

`mip:nodestrategy` (`nodeStrategy`: `hybrid`, `fewest`, `depth`, `upfewest`, …) picks the
next node. `int:strongBranching` (default 5 variables) and `int:trustPseudoCosts`
(default 5 branches) tune branching. `mip:heuristics` (`heuristicsOnOff`) switches most
primal heuristics; individual ones include `mip:rins`, `mip:rens`, `mip:dins`,
`mip:proximitysearch`, `mip:localtreesearch`, the `mip:diving*` family and the
feasibility pump (`int:passFeasibilityPump`, `double:pumpCutoff`).

## Numerical issues

`double:primalTolerance` and `double:dualTolerance` (default 1e-7), and
`double:integerTolerance` (default 1e-7) are the main tolerances; `pre:scaling`
(`scaling`) controls scaling, `double:preTolerance` the presolve tolerance.

## Cuts

`cut:cut` (`cutsOnOff`: `off`, `on`, `root`, `ifmove`, `forceOn`) switches all cut
generators; individual families: `cut:gomorycuts`, `cut:gmicuts`, `cut:knapsackcuts`,
`cut:flowcovercuts`, `cut:twomircuts`, `cut:liftandprojectcuts`,
`cut:residualcapacitycuts`, `cut:reduceandsplitcuts`, and `mixedIntegerRoundingCuts`.
`int:passCuts` (default 20) sets the number of root cut rounds; `int:cutDepth` the tree
depth at which cuts are generated.

```ampl
option cbc_options 'cutsOnOff=root gomoryCuts=on passCuts=30';
```

## Presolve and algorithm

`pre:presolve` (`presolve`: `on`, `off`, `more`) and `pre:preprocess` (`preprocess`,
integer preprocessing: `off`, `on`, `sos`, `equal`, `aggregate`, …). `alg:start`
(`warmstart`, default 3) uses incoming values as a warm start; `alg:basis` passes a basis.
LP pivoting: `lp:dualpivot`, `lp:primalpivot`. Random seeds: `int:randomCbcSeed` (CBC,
default -1) and `int:randomSeed` (Clp, default 1234567). The option list has no thread
count.

## See also

- `../mp-library/feature-and-solver-options-guide.md` — cross-solver mechanics and the MP
  support table
- `../core-language/13-solver-selection-guide.md` — what CBC can and cannot solve
- `highs-options.md` — the other open-source LP/MIP solver
- Exhaustive option list: `raw/cbc-mp-options.md`,
  `https://dev.ampl.com/solvers/cbc/options.html`
