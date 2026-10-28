# SCIP Options

Derived from: scip-mp-options.md

Source: `raw/scip-mp-options.md` (`https://dev.ampl.com/solvers/scip/options.html`),
current as of 2026-10-28. SCIP is reached through an MP-based driver (`scip`, 294 option
entries). **This is a curated subset of commonly-tuned options**; see the raw source for
the full list.

SCIP is open source and covers LP, MILP, QP/MIQP, convex and non-convex (MI)QCP, conic and
(MI)NLP, solving nonlinear models **globally**. It receives
`and`/`or`, `abs`, quadratic constraints and the main nonlinear functions natively as
expression trees (`../mp-library/tools-troubleshooting-and-reformulation.md`). In the MP
feature table it supports model and solution export, IIS, multiple solutions, warm start,
fixed model (emulated), MIP-gap and best-bound return, and (emulated) multiple
objectives; not feasibility relaxation, sensitivity, basis I/O or plateau stop.

## Setting options

```ampl
option solver scip;
option scip_options 'outlev=1 timelim=300 mipgap=1e-3';
solve;
```

Native SCIP parameters without an MP name can be set with `tech:optionnative`
(`param`), and SCIP settings files read/written with
`tech:optionnativeread`/`tech:optionnativewrite`. General mechanics:
`../mp-library/feature-and-solver-options-guide.md`.

## Verbosity

`tech:outlev` (`outlev`), 0 (default) or 1; `tech:outlevnative` sets SCIP's own
verbosity; `tech:logfile` writes the log to a file.

## Presets

SCIP's quickest levers are its preset groups:

- `alg:emphasis` (`emphasis`): 0 default, 1 cpsolver, 2 easycip, 3 feasibility, 4 hardlp,
  5 optimality, 6 counter, 7 phasefeas, … (applied after individual parameters);
- `cut:settings`, `heu:settings`, `pre:settings`: 0 default, 1 aggressive, 2 fast, 3 off.

```ampl
option scip_options 'emphasis=3 heu:settings=1';   # find a feasible point fast
```

## MIP stopping criteria

| Option | Effect |
|---|---|
| `lim:time` (`timelim`) | Time limit in seconds |
| `lim:softtime` (`softtime`) | Time limit that applies once a first solution is found (default -1, disabled) |
| `mip:gap`, `mip:gapabs` (`mipgap`, `mipgapabs`) | Relative / absolute gap |
| `lim:nodes`, `lim:totalnodes`, `lim:stallnodes` | Node limits (current run, total, without improvement) |
| `lim:sol` (`sollim`), `lim:bestsol` | Number of solutions found / improving solutions |
| `lim:bestobjstop`, `lim:bestbndstop` | Stop once the primal objective / dual bound reaches a value |
| `lim:memory` (`memlim`) | Memory limit |

## Cuts and branching

`cut:settings` as above; individual families (`cut:gomory`, `cut:mir`, `cut:cover`,
`cut:flowcover`, `cut:clique`, `cut:zerohalf`, `cut:mcf`, `cut:rlt`, `cut:oddcycle`,
`cut:strongcg`, …) and limits (`cut:maxrounds`, `cut:maxroundsroot`, `cut:maxcuts`,
`cut:maxcutsroot`). `branch:preferbinary` prefers branching on binaries;
`nod:childsel` selects the child node.

## Numerical issues

`alg:feastol` (`feastol`) and `alg:dualfeastol` are the feasibility tolerances;
`num:epsilon`, `num:sumepsilon` and `num:infinity` the zero/infinity thresholds;
`lp:scaling` (`scale`) the LP scaling.

## Algorithm, parallelism, seeds

`alg:method` (`lpmethod`) for the initial LP relaxations: `s` automatic simplex
(default), `p` primal, `d` dual, `b` barrier, `c` barrier with crossover (with
SoPlex as LP solver, which has no barrier, both run the dual simplex). `tech:threads` with `alg:concurrent`
(-1 default: concurrent solvers if `threads > 1`) and `par:mode` (0 opportunistic, 1
deterministic, default) control parallel solving. Seeds for repeated runs
(`../benchmarking-and-validation.md`): `tech:seed` (`randomseedshift`), `tech:permseed`,
`tech:lpseed`; `ran:permuteconss`/`ran:permutevars` permute the model.

## Infeasibility, pools, fixed model

- `iis:find` (`iis`), with `iis:irreducible`, `iis:bounds`, `lim:iistime`, `lim:iisnodes`.
- Solution pool: `sol:stub`, `sol:count`, `sol:poollimit`, `sol:poolgap`.
- `mip:basis` (`fixmodel`): duals/basis for MIP by fixing the integers to an incumbent
  and solving a continuous model (linear algebraic models only).

## See also

- `../mp-library/expressions-and-modeling-guide.md` — global nonlinear solving by solver
  class (SCIP, Gurobi, Xpress)
- `../core-language/13-solver-selection-guide.md`
- Exhaustive option list: `raw/scip-mp-options.md`,
  `https://dev.ampl.com/solvers/scip/options.html`
