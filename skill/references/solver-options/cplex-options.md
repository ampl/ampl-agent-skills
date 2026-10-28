# CPLEX Options

Derived from: cplex-mp-options.md, cplex-asl-options.md

Source: `raw/cplex-mp-options.md` (`https://dev.ampl.com/solvers/cplex/options.html`,
MP-interface names — the recommended interface) and `raw/cplex-asl-options.md`
(`https://dev.ampl.com/solvers/cplex/cplexasl.html`, legacy ASL-interface names),
current as of 2026-10-28. **This is a curated subset of commonly-tuned options** — the
handful a practitioner actually reaches for, not the full reference; see the raw sources
or the URLs above for the complete list. Option names below use the MP-interface
(`cplex_options`) form; the ASL flat names are nearly all just aliases of the same knobs
(shown in parentheses) and are omitted below except where a genuinely useful knob exists
under ASL with no MP equivalent found in the captured option dump.

## Setting options

```ampl
option solver cplex;
option cplex_options 'outlev=1 timelim=300 mipgap=0.01';
solve;
```

MP option names take `prefix:name` form (e.g. `mip:gap`); legacy flat aliases (`mipgap`)
still work and are listed in parentheses in the raw reference. Whole CPLEX `.prm`
parameter files can be read/written with `tech:optionnativeread`/`tech:optionnativewrite`
(aliases `tech:param:read`/`tech:param:write`). The CPLEX driver has **no**
`tech:optionnative` option for single native parameters.
General mechanics (`(solver)_options` vs. `mp_options`, option files, querying values):
see `../mp-library/feature-and-solver-options-guide.md`.

## Verbosity

`tech:outlev` (`outlev`) — 0 (default, silent), 1, or 2, how much CPLEX log chatter to
print; for finer control see `tech:lpdisplay`, `tech:mipdisplay`, `tech:bardisplay`.

```ampl
option cplex_options 'outlev=2';
```

## Autotuner

CPLEX has a built-in tuning tool, invoked from AMPL via `tech:tunefile`: give it a
filename and CPLEX experiments with parameter settings that would make future solves
faster, writing the winning combination to that file in CPLEX PRM format (this can
significantly increase the time of the *current* invocation). Related knobs:
`tech:tunetimelim` (time budget, default: none), `tech:tunerepeat` (how many times to
perturb the problem while tuning, default 1), `tech:tunedisplay` (verbosity: 0 nothing,
1 minimal (default), 2 show parameters tried, 3 exhaustive). Reapply the winning set in
a later solve with `tech:optionnativeread`.

```ampl
option cplex_options 'tunefile=tuned.prm tunetimelim=600 tunedisplay=2';
solve;
option cplex_options 'optionnativeread=tuned.prm';   # apply the tuned settings later
```

## MIP stopping criteria

| Option | Effect |
|---|---|
| `lim:time` (`timelim`) | Wall-clock time limit in seconds |
| `mip:gap` (`mipgap`) | Max. relative optimality gap to stop at (default 1e-4) |
| `mip:gapabs` (`mipgapabs`) | Max. absolute optimality gap to stop at (default 1e-6) |
| `lim:nodes` (`nodelim`) | Max. branch-and-bound nodes explored (default: 2^31-1) |
| `lim:sol` (`sollimit`) | Stop after this many feasible solutions found |
| `lim:uppercutoff` (`uppercutoff`) | Discard/declare-infeasible any solution worse than this bound (minimization) |
| `lim:upperobjstop` (`upperobjstop`) | Stop as soon as a solution at least this good is found (maximization; "good enough, stop now") |

CPLEX has no stall/plateau-based MIP termination (contrast with HiGHS's `mip:plateau:*`
family) — the closest analogues are the cutoff/target options above and `mip:objdiff`,
which forces the search to ignore new incumbents that aren't at least a fixed amount
better than the current best (a crude way to reduce "wasted" reporting overhead late in
a search, not a stopping criterion by itself).

```ampl
option cplex_options 'timelim=300 mipgap=0.01 mipgapabs=1e-6 nodelim=500000';
```

## Variable/branch selection

`mip:varbranch` (`varbranch`) picks the branching-variable strategy: -1 smallest integer
infeasibility, 0 automatic (default), 1 largest integer infeasibility, 2 pseudo costs, 3
strong branching, 4 pseudo reduced costs. `mip:branchdir` (`branchdir`) picks which
child node to explore first (-1 down, 0 automatic/"most promising" (default), 1 up).
`mip:nodesel` (`nodeselect`) picks the node-selection strategy: 0 depth-first, 1
breadth-first (default), 2 best-estimate, 3 alternative best-estimate. `mip:emphasis`
(`mipemphasis`) is a coarser overall-strategy knob worth knowing alongside these: 0
balanced (default), 1 favor feasibility, 2 favor optimality, 3 focus on the bound, 4
find hidden feasible solutions, 5 find high-quality solutions early (heuristic).

```ampl
option cplex_options 'varbranch=3 mipemphasis=1';
```

## Numerical issues

`alg:numericalemphasis` (`numericemphasis`) — 0 (default) or 1, whether to try harder
for numerical accuracy at a possible cost of time/memory; the first thing to raise when
a solve reports inconsistent bases, near-infeasible "optimal" solutions, or results that
change with trivial model perturbations. `alg:feastol` (`feastol`, default 1e-6) and
`mip:inttol` (`intfeastol`, default 1e-5) are the primal/integer feasibility tolerances —
loosen cautiously if a model is chronically declared infeasible on marginal violations.
`lp:opttol` (`optimality`, default 1e-6) is the dual/reduced-cost optimality tolerance.
`pre:scale` (`scale`) controls automatic problem scaling: -1 off, 0 equilibration
(default), 1 more aggressive — worth adjusting on models with widely-varying coefficient
magnitudes. `alg:kappa` (`basis_cond`) reports the basis condition number, a diagnostic
for how numerically unstable the final basis is.

```ampl
option cplex_options 'numericemphasis=1 scale=1 feastol=1e-9';
```

## Cuts

`cut:cuts` (`mipcuts`) is the global cut-generation dial: -1 disallow, 0 automatic
(default), 1 moderate, 2 aggressive, 3 very aggressive. Individual families can override
it the same way, e.g. `cut:clique`, `cut:cover`, `cut:frac` (Gomory), `cut:mir`,
`cut:disj`, `cut:zerohalf`, `cut:flowcover`, `cut:rlt` (same -1/0/1/2 scale) — reach for
these only if the global dial isn't enough and one cut family is a known bottleneck.
`cut:passes` (`cutpasses`) limits root-node cutting-plane passes (-1 none, 0 automatic
(default), n>0 fixed count); `cut:factor` (`cutfactor`) caps the total number of cuts
added relative to the problem's row count.

```ampl
option cplex_options 'cuts=2 mircuts=-1';   # aggressive cuts overall, but disable MIR cuts
```

## Concurrent and algorithm selection

`alg:method` (`method`/`lpmethod`) selects the algorithm for LPs and the MIP root node:
0 automatic (default), 1 primal simplex, 2 dual simplex, 3 network simplex, 4 barrier, 5
sifting, 6 concurrent (dual, barrier, and primal race in opportunistic mode — deterministic
mode uses dual+barrier — and the first to finish wins). `mip:nodemethod`
(`mipalgorithm`) selects the algorithm used for MIP node relaxations after the root,
same value scale as `alg:method`. `pre:solve` (`presolve`) controls CPLEX's own presolve:
0 off, 1 on (default) — turning it off helps when diagnosing whether a bad solve is a
presolve artifact. `tech:threads` (`threads`) sets the thread count for barrier/MIP
(default 0 = automatic).

```ampl
option cplex_options 'method=6';   # concurrent optimization for the LP/root relaxation
```

## Changes in the October 2026 option list

- **`alg:netfind` values renumbered**: now 1 = extract pure network only, 2 = try
  reflection scaling (default), 3 = try general scaling (previously 0/1/2).
- `cut:mfc` corrected to `cut:mcf` (multi-commodity flow cuts; the old name is an alias).
- New families: `mip:polishafter:*` (absgap, dettime, gap, nodes, sols, time),
  `alg:feasopt`/`alg:feasoptobj`, sifting (`alg:siftalg`, `alg:siftsimplex`,
  `lim:siftiter`), pricing (`lp:pricing`, `lp:pgradient`), `mip:start:effort`,
  `mip:symmetry`, `obj:multi:stats`, `mip:basis:timelimit`/`iterlimit`/`method`.
- Defaults formerly given as `2^31 - 1` now read "no limit"; many new aliases.

## See also

- General solver-options mechanics (`(solver)_options` vs. `mp_options`, native
  options, option files): `../mp-library/feature-and-solver-options-guide.md`
- Choosing a solver in the first place: `../core-language/13-solver-selection-guide.md`
- MIP-specific modeling advice (warm starts, gap tolerances in context):
  `../modeling-patterns/integer-programming.md`
