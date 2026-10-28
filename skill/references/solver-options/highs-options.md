# HiGHS Options

Derived from: highs-mp-options.md

Source: `raw/highs-mp-options.md` (`https://dev.ampl.com/solvers/highs/options.html`),
current as of 2026-10-28 (248 options). Many options now have short names; the longer names used below are still accepted as aliases. HiGHS only has an MP-interface driver (no separate ASL
variant), so this is the only source. **This is a curated subset of commonly-tuned
options** — the handful a practitioner actually reaches for, not the full reference; see
the raw source or the URL above for the complete list.

## Setting options

```ampl
option solver highs;
option highs_options 'outlev=1 timelim=300 mip:gap=0.01';
solve;
```

MP option names take `prefix:name` form (e.g. `mip:gap`); legacy flat aliases (`mipgap`,
`timelim`) still work and are listed in parentheses in the raw reference. General
mechanics (`(solver)_options` vs. `mp_options`, option files, querying values): see
`../mp-library/feature-and-solver-options-guide.md`.

## Verbosity

`tech:outlev` (`outlev`) — 0 (default, silent) or 1, whether to write HiGHS's log lines
to stdout and to file.

```ampl
option highs_options 'outlev=1';
```

## Autotuner

**Not available.** HiGHS's option dump has no tuning-tool entry (no `tune*` keyword
anywhere in the reference) — unlike CPLEX or Gurobi, there is no automatic
parameter-search feature to invoke from AMPL. Tuning HiGHS means adjusting the options
below by hand.

## MIP stopping criteria

| Option | Effect |
|---|---|
| `lim:time` (`timelim`) | Wall-clock time limit in seconds |
| `mip:gap` (`mipgap`) | Max. relative optimality gap to stop at (default 1e-4) |
| `mip:gapabs` (`mipgapabs`) | Max. absolute optimality gap to stop at (default 1e-6) |
| `lim:nodes` (`nodelim`) | Max. branch-and-bound nodes explored |
| `lim:leavenodes` (`leaveslim`) | Max. number of leaf nodes |
| `lim:stallnodes` (`stallnodelim`) | Max. nodes whose bound estimate stays above the cutoff (a node-count-based stall limit) |
| `lim:sol` (`sollim`, old `lim:improvingsols`) | Stop after this many improving solutions found |
| `lim:objectivetarget` (`objectivetarget`) | Stop once the MIP search reaches this objective value ("good enough, stop now") |

HiGHS additionally has a genuine time-based **plateau stop**, the `mip:plateau:*`
family: `mip:plateau:time` stops the search if the incumbent (and, if
`mip:plateau:absgaptol`/`mip:plateau:relgaptol` are set, the gap) hasn't improved by at
least `mip:plateau:abstol`/`mip:plateau:reltol` for this many seconds.
`mip:plateau:warmup` gives a grace period before the timer starts checking, and
`mip:plateau:log` prints plateau status. This is the "stop once progress has stalled"
knob to reach for instead of a hard time limit. `abstol` and `reltol` combine with OR and
`abstol` defaults to 0 (any change counts), so set `abstol` too when using `reltol`
(`../mp-library/feature-and-solver-options-guide.md`).

```ampl
option highs_options 'timelim=300 mip:gap=0.01 mip:plateau:time=60 mip:plateau:abstol=1e-6 mip:plateau:reltol=1e-4';
```

## Variable/branch selection

**No user-selectable branching-variable strategy or node-selection option is exposed** —
unlike CPLEX/Gurobi's `varbranch`/`nodesel`, HiGHS's raw option dump has no `branch` or
`nodesel` keyword; branching is internal pseudo-cost-based logic. The closest tuning
knobs are `mip:pscostreliability` (`pscostreliability`, default 8 — minimum
observations before a variable's pseudo cost is trusted) and `mip:heureff`
(`heureff`, default 0.05 — fraction of time budget spent in MIP
heuristics, which indirectly shapes how much of the search is spent finding incumbents
vs. proving the bound).

```ampl
option highs_options 'mip:heureff=0.2';   # spend more effort on heuristics
```

## Numerical issues

`alg:feastol` (`feastol`, default 1e-7) and `alg:dualfeastol`
(`dualfeastol`, default 1e-7) are the primal/dual feasibility tolerances;
`mip:intfeastol` (`intfeastol`, default 1e-6) is the integer feasibility
tolerance — loosen cautiously if a model is chronically declared infeasible on marginal
violations. `alg:kkttol` (`kkttol`, old `alg:kkt_tolerance`, default 1e-7; if changed, it overrides all the individual feasibility/optimality tolerances) and `alg:ipmopttol`
(`ipmopttol`, default 1e-8) govern the interior-point method's stopping
tolerance. `alg:simplexscale` (`simplexscale`) controls problem scaling for
the simplex solver: 0 off, 1 automatic (default), 2 equilibration, 3 forced
equilibration, 4/5 max-value variants — worth adjusting on models with widely-varying
coefficient magnitudes. There is no single "numeric emphasis" master switch like
CPLEX/Gurobi's `numericfocus`; these tolerances/scaling knobs are adjusted individually.

```ampl
option highs_options 'alg:simplexscale=2 mip:intfeastol=1e-7';
```

## Cuts

**No per-family cut controls.** The option dump has no `cut:` family — HiGHS's MIP solver
generates cuts internally. The adjacent knobs are `mip:nodecuts` (`nodecuts`, 0/1, default
1: whether cuts are separated at nodes other than the root) and `mip:poolsoftlimit`
(`poolsoftlimit`, default 10000: a soft cap on the cut pool's row count for dynamic aging).

## Concurrent and algorithm selection

`alg:method` (`method`/`lpmethod`) selects the algorithm for non-MIP problems: `choose`
automatic (default), `simplex`, `ipm` (interior point), `hipo` (HiGHS's own
interior-point method), `ipx`, `pdlp`/`pdlp-gpu` (first-order PDLP solver, GPU variant
needs CUDA), `hipdlp`/`hipdlp-gpu`, or `qpasm` for QPs. HiGHS has **no CPLEX/Gurobi-style
concurrent mode** (racing multiple algorithms and keeping the first to finish) — only
one algorithm runs per solve. `alg:parallel` (`parallel`) instead controls
*intra-algorithm* parallelism (`choose`/`off`/`on`), and `alg:simplex`
(`simplex`) picks a parallel simplex variant (dual serial, dual PAMI, dual SIP,
primal). `pre:solve` (`presolve`) controls HiGHS's own presolve: `choose` automatic
(default), `off`, `on` — turning it off helps when diagnosing whether a bad solve is a
presolve artifact.

```ampl
option highs_options 'method=ipm parallel=on';
```

## New in the October 2026 option list

- **Infeasibility tools:** `iis:find` (`iis`), `alg:feasrelax` with `alg:lbpen`/`ubpen`/
  `rhspen`, and `lim:iistime` — HiGHS now appears with IIS and feasibility relaxation in
  the MP support table.
- **Sensitivity and fixed model:** `alg:sens`; `mip:basis` (emulated fixed-model solve,
  with `mip:basis:timelimit`/`iterlimit`).
- **MIP heuristics:** `mip:heur:feasjump`, `mip:heur:rens`, `mip:heur:rins`,
  `mip:heur:rootredcost`, `mip:heur:shifting`, `mip:heur:ziround` (0/1 each).
- **Iteration limits renamed:** `lim:iter` (simplex), `bar:iterlim` (IPM), `lim:pdlpiter`,
  `lim:qpiter` — old long names kept as aliases.
- `alg:method=hipo` (HiPO interior point) is not available in every HiGHS build and is
  rejected with a message if missing.
- **Removed:** `obj:blend` (use MP's `obj:multi`, `../mp-library/multi-objective-optimization.md`).

## See also

- General solver-options mechanics (`(solver)_options` vs. `mp_options`, native
  options, option files): `../mp-library/feature-and-solver-options-guide.md`
- Choosing a solver in the first place: `../core-language/13-solver-selection-guide.md`
- MIP-specific modeling advice (warm starts, gap tolerances in context):
  `../modeling-patterns/integer-programming.md`
