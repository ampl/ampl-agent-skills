# NVIDIA cuOpt Options

Derived from: cuopt-mp-options.md

Source: `raw/cuopt-mp-options.md` (`https://dev.ampl.com/solvers/cuopt/options.html`),
current as of 2026-10-28. cuOpt is reached through an MP-based driver (83 option entries,
the full list is short enough to read in the raw file). It is a GPU-accelerated LP and
MILP solver; quadratic and nonlinear terms are approximated piecewise-linearly by MP
(`../core-language/13-solver-selection-guide.md`).

## Setting options

```ampl
option solver cuopt;
option cuopt_options 'outlev=1 timelimit=300';
solve;
```

**Flag — option-string name.** The page's usage example uses `cuopt_options`, but the
option dump's own header (driver banner `CUOPTLP`) says to set `cuoptmp_options`. If
options seem to be ignored, check which name your installed driver reads (`cuopt -=`
prints the header). General mechanics: `../mp-library/feature-and-solver-options-guide.md`.

In the MP feature table cuOpt supports solution export, solution-time reporting, MIP-gap
and best-bound return, and (emulated) multiple objectives — but not model export, warm
start, basis I/O, multiple solutions, IIS, feasibility relaxation, sensitivity or plateau
stop.

## Verbosity

`tech:outlev` (`outlev`) logs to the console; `tech:consolelog` controls console logging
during a solve.

## Algorithm

`alg:method` (`method`) for LP: 0 concurrent (default), 1 PDLP, 2 dual simplex.
`alg:solver_mode` (`solver_mode`) selects the PDLP mode: 0 Stable1, 1 Stable2 (default),
2 Methodical1, 3 Fast1. `lp:crossover` (`crossover`) computes a basic solution after
PDLP; `lp:infeasdetect` enables PDLP infeasibility detection. `lim:ncputhreads` sets the
CPU threads used by the LP and MIP solvers.

## Limits and tolerances

| Option | Effect |
|---|---|
| `lim:timelimit` (`timelimit`) | Time limit in seconds; the current solution is returned |
| `lim:iterations` (`iterations`) | Iteration limit |
| `lp:relgaptol`, `lp:absgaptol` | PDLP duality-gap tolerances |
| `lp:relprimaltol`, `lp:absprimaltol`, `lp:reldualtol`, `lp:absdualtol` | PDLP primal/dual feasibility tolerances |
| `mip:reltol`, `mip:abstol`, `mip:absgap` | MIP tolerances (`mip:absgap` terminates the MIP solve on an absolute gap) |
| `mip:inttol` (`inttol`) | Integrality tolerance |
| `mip:return_gap`, `mip:bestbound` | Return the final gap and dual bound (MP standard) |

`mip:hueristicsonly` (spelled so in the driver) runs only the GPU heuristics, and
`mip:scale` applies scaling to MIP problems.

```ampl
option cuopt_options 'method=1 solver_mode=3 crossover=1 timelimit=120';
```

## See also

- `highs-options.md`, `gurobi-options.md`, `xpress-options.md`, `copt-options.md` — other
  solvers with GPU-accelerated (PDLP) LP algorithms
- `../mp-library/feature-and-solver-options-guide.md` — MP support table
- Exhaustive option list: `raw/cuopt-mp-options.md`,
  `https://dev.ampl.com/solvers/cuopt/options.html`
