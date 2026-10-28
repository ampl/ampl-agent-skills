# XPRESS Options

Derived from: xpress-mp-options.md, xpress-asl-options.md

Source: `raw/xpress-mp-options.md` (`https://dev.ampl.com/solvers/xpress/options.html`,
MP interface, complete — 792 entries) and `raw/xpress-asl-options.md`
(`https://dev.ampl.com/solvers/xpress/xpressasl.html`, legacy ASL interface), both
current as of 2026-10-28. **This is a curated subset of commonly-tuned options**; see the
raw sources for the complete lists.

**Option names changed upstream in 2026.** The MP driver's canonical names dropped their
`xprs_`/`xslp_` prefixes (e.g. `bar:xprs_algaftercrossover` → `bar:algaftercrossover`,
`alg:xslp_multistart` → `slp:multistart`). The old prefixed names are **not** accepted as
aliases; the bare short names and the Xpress parameter names (`XPRS_...`) are. The
`xktr:param_*` options (Knitro inside Xpress) were removed.

## Passing options

Two AMPL drivers exist for XPRESS, each with its own option string:

```ampl
option solver xpress;                          # MP interface (recommended)
option xpress_options 'mipgap=1e-6 outlev=1';
solve;
```
```ampl
option solver xpressasl;                        # legacy ASL interface
option xpressasl_options 'timelimit=300 outlev=1';
solve;
```

Many MP entries list the old ASL short names as aliases (e.g. `mip:gap` also accepts
`mipgap` and `miprelstop`; `lim:nodes` accepts `maxnode`), so most ASL names also work in
`xpress_options`. In the ASL driver, `maxtime` is **deprecated** in favour of `timelimit`
and `soltimelimit`, and `poolfeastol`/`poolmiptol` were removed.

## Verbosity

`tech:outlev` (`outlev`): 1 all, 2 information, 3 warnings and errors only (default), 4
errors, 0 or 5 none.

```ampl
option xpress_options 'outlev=1';
```

## Autotuner

The tuner runs only when `tech:tunebase` (`tunerdir`) is given; results go to a subfolder
per problem under that path. `tech:tunermethod` picks a factory method (-1 automatic, 0
LP, 1 MIP, 2 comprehensive MIP, 3 root-focus, 4 tree-focus, 5 simple MIP, 6 SLP, 7 MISLP,
8 primal-heuristic focus, 9 Xpress Global); `tech:tunetimelim` (`tunermaxtime`),
`tech:tunerthreads`, `tech:tunertarget` and `tech:tunermode` bound and steer it.

```ampl
option xpress_options 'tunebase=xpress_tuner tunermethod=1 tunetimelim=600';
```

## MIP stopping criteria

| Option | Effect |
|---|---|
| `lim:time` (`timelimit`) | Time limit in seconds, setup included (default 1e20) |
| `lim:soltime` (`soltimelimit`) | Time limit once a feasible MIP solution has been found |
| `mip:gap` (`mipgap`, `miprelstop`) | Stop when `\|obj − bound\| ≤ gap × max(\|bound\|, \|obj\|)` |
| `mip:gapabs` (`mipgapabs`, `mipabsstop`) | Absolute gap |
| `lim:nodes` (`maxnode`) | Max. branch-and-bound nodes |
| `lim:mipsol` (`maxmipsol`) | Max. integer solutions to find |
| `lim:stalltime` (`maxstalltime`), `lim:work` | Stop after a period without improvement / after a deterministic work limit |

```ampl
option xpress_options 'timelimit=300 mipgap=0.01 maxnode=100000';
```

## Variable/branch selection

`mip:varselection` (`varselection`) chooses the estimate formula used to pick the
branching variable. `mip:sbeffort`, `mip:sbselect` and `mip:sbiterlimit` tune strong
branching; `mip:pseudocost` sets the initial pseudocost.

```ampl
option xpress_options 'varselection=2 sbeffort=2';
```

## Numerical issues

`alg:numericalemphasis` (aliases `numericfocus`, `numfocus`) trades speed for numerical
stability, 0 (speed) to 3 (strong stability), default automatic. `alg:feastol` is the
primal feasibility tolerance (default 1e-6); `mip:intfeastol` (`inttol`, `miptol`) the
integrality tolerance (default 5e-6); `pre:scaling` (`scaling`) a bit vector for internal
rescaling (0 = none).

```ampl
option xpress_options 'numericfocus=2 feastol=1e-7 miptol=1e-7';
```

## Cuts

`cut:strategy` sets overall aggressiveness: -1 automatic, 0 none, 1 conservative, 2
moderate, 3 aggressive. `cut:freq` sets how often cuts are regenerated in the tree;
`cut:select` / `cut:treeselect` are bit vectors choosing the cut families at the root and
in the tree.

```ampl
option xpress_options 'cut:strategy=3';
```

## Concurrent and algorithm selection

`alg:method` (`method`, `lpmethod`, `defaultalg`) picks the LP algorithm: 1 automatic, 2
dual simplex, 3 primal simplex, 4 Newton barrier (or hybrid gradient with `BARALG=4`).
`pre:solve` (`presolve`) switches presolve; `mip:concurrentsolves` / `mip:concurrentnodes`
control concurrent MIP solves; `tech:threads` / `mip:threads` set parallelism;
`tech:seed` (`randomseed`) the random seed. For nonlinear models, Xpress solves globally
if its license allows; `alg:nlpsolver=1` selects local solving
(`../mp-library/expressions-and-modeling-guide.md`).

```ampl
option xpress_options 'method=4 presolve=1 mipconcurrentsolves=2 threads=8';
```

## See also

- `../mp-library/feature-and-solver-options-guide.md` — cross-solver option mechanics,
  plateau stop, solution export
- `../core-language/13-solver-selection-guide.md` — choosing XPRESS vs. other solvers
- `../modeling-patterns/integer-programming.md` — MIP gap tolerances and warm starts in
  modeling context
- Exhaustive option lists: `raw/xpress-mp-options.md`, `raw/xpress-asl-options.md`,
  `https://dev.ampl.com/solvers/xpress/options.html`,
  `https://dev.ampl.com/solvers/xpress/xpressasl.html`
