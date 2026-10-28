# Gurobi Options

Derived from: gurobi-mp-options.md, gurobi-asl-options.md

Source: `raw/gurobi-mp-options.md` (`https://dev.ampl.com/solvers/gurobi/options.html`,
MP-interface names — the recommended interface, ~362 top-level options) and
`raw/gurobi-asl-options.md` (`https://dev.ampl.com/solvers/gurobi/gurobiasl.html`,
legacy ASL-interface names), current as of 2026-10-28. **This is a curated subset of
commonly-tuned options** — the handful a practitioner actually reaches for, not the full
reference. See the raw sources or the URLs above for the complete list. Option names
below use the MP-interface (`gurobi_options`) form; the older flat ASL names
(`gurobiasl_options`) are nearly all just aliases of the same knobs (shown in
parentheses) and are omitted below except where noted.

## Setting options

```ampl
option solver gurobi;
option gurobi_options 'outlev=1 lim:time=300 mip:gap=0.01';
solve;
```

MP option names take `prefix:name` form; legacy flat aliases (e.g. `timelim`,
`mipgap`) still work and are listed in parentheses in the raw reference. Both
`key=value` and `key value` syntax are accepted inside the string. A native Gurobi
parameter with no MP-standardized name can still be set via `tech:optionnative`, e.g.
`option gurobi_options 'tech:optionnative "NumericFocus 3"';`. General mechanics
(`(solver)_options` vs. `mp_options`, option files, querying values): see
`../mp-library/feature-and-solver-options-guide.md`.

## Verbosity

`tech:outlev` (`outlev`) — 0\*/1, whether to write Gurobi's solve log to stdout.

```ampl
option gurobi_options 'outlev=1';
```

## Autotuner

Gurobi has a built-in automatic parameter search, invoked from AMPL via
`tech:tunebase`: give it a base filename and Gurobi searches for a better parameter
set than the defaults, writing results to `<base>_1.prm`, `<base>_2.prm`, ... (best
first) — reapply the winning set in a later solve with `tech:param:read=...`. Related
knobs: `tech:tunetimelim` (time budget, default 86400 s), `tech:tunetrials` (trials
per candidate set, default 0 = automatic), `tech:tuneoutput` (verbosity while tuning),
`tech:tunejobs`/`tech:tunedynamicjobs` (distribute tuning across parallel
workers/machines).

```ampl
option gurobi_options 'tech:tunebase=mytune tech:tunetimelim=120';
solve;
```

## MIP stopping criteria

| Option | Effect |
|---|---|
| `lim:time` (`timelim`) | Wall-clock time limit in seconds |
| `mip:gap` (`mipgap`) | Max. relative optimality gap to stop at (default 1e-4) |
| `mip:gapabs` (`mipgapabs`) | Max. absolute optimality gap to stop at (default 1e-10) |
| `lim:nodes` (`nodelim`) | Max. branch-and-bound nodes explored |
| `lim:sol` (`sollimit`) | Stop after this many feasible solutions found |
| `mip:bestobjstop` (`bestobjstop`) | Stop once a feasible solution at least this good is found ("good enough, stop now") |
| `mip:bestbndstop` (`bestbndstop`) | Stop once the best bound is at least this good (proves quality without full convergence) |

```ampl
option gurobi_options 'lim:time=300 mip:gap=0.01 lim:sol=5';
```

## Variable/branch selection

`mip:varbranch` (`varbranch`) picks the branching-variable strategy: -1 automatic
(default), 0 pseudo-reduced-cost, 1 pseudo-shadow-price, 2 maximum infeasibility, 3
strong branching. `mip:branchdir` (`branchdir`) picks which child node to explore
first (-1 down, 0 automatic, 1 up). `mip:priorities` (0/1\*, default on) tells Gurobi
to read per-variable branch priority from the `.priority` suffix, letting a model
force certain variables to be branched on first. `mip:focus` (`mipfocus`) is a coarser
overall-strategy knob worth knowing alongside these: 0 balanced (default), 1 favor
finding feasible solutions, 2 favor proving optimality, 3 focus on improving the bound.

```ampl
option gurobi_options 'mip:varbranch=3 mip:focus=1';
```

## Numerical issues

`alg:numericfocus` (`numericfocus`) — 0 automatic (default), 1-3 increasing focus on
numerically stable computations; the first thing to raise when a solve reports
inconsistent bases, near-infeasible optimal solutions, or results that change with
trivial model perturbations. `alg:feastol` (`feastol`, default 1e-6) and `mip:inttol`
(`inttol`/`intfeastol`, default 1e-5) are the primal/integer feasibility tolerances —
loosen them cautiously if a model is chronically "declared infeasible" on marginal
violations. `pre:scale` (`scale`) controls automatic problem scaling (-1 automatic, 0
off, 1-3 increasingly aggressive) — worth adjusting on models with very large
coefficient-magnitude ranges. `mip:intfocus` is Gurobi's own suggested first stop for
integrality-precision issues ("more impact than raising `mip:inttol`" per its own
docs).

```ampl
option gurobi_options 'alg:numericfocus=3 pre:scale=2';
```

## Cuts

`cut:cuts` (`cuts`) is the global cut-generation dial: -1 automatic (default), 0 no
cuts, 1 conservative, 2 aggressive, 3 very aggressive. Individual families can
override it the same way, e.g. `cut:gomory`, `cut:clique`, `cut:cover`, `cut:mir`,
`cut:zerohalf`, `cut:flowcover` (same -1/0/1/2 scale as `cut:cuts`) — reach for these
only if the global dial isn't enough and one cut family is known to be a bottleneck.
`cut:agg` (`cutagg`/`cut:aggpasses`) limits constraint-aggregation passes during cut
generation.

```ampl
option gurobi_options 'cut:cuts=0';    # disable cuts entirely, e.g. to isolate a modeling bug
```

## Concurrent and algorithm selection

`alg:method` (`method`/`lpmethod`) selects the LP/root-node algorithm: -1 automatic
(default: 3 for LP, 2 for QP, varies for MIP), 0 primal simplex, 1 dual simplex, 2
barrier, 3 nondeterministic concurrent (multiple algorithms racing, first to finish
wins), 4 deterministic concurrent. `alg:concurrentmethod` fine-tunes which algorithms
compete when concurrent mode is used (barrier+dual, barrier+primal, dual+primal).
`pre:solve` (`presolve`) controls Gurobi's own presolve: -1 automatic (default), 0
off, 1 conservative, 2 aggressive — turning it off can help when diagnosing whether a
bad solve is a presolve artifact. At the MIP level, `tech:concurrentmip` runs several
independent full MIP solves with different settings in parallel (first to finish
wins), and `tech:pooljobs`/`tech:distmip` extend concurrent solving across a
distributed worker pool.

```ampl
option gurobi_options 'alg:method=2 pre:solve=0';   # force barrier, no presolve
```

## Changes in the October 2026 option list

- **`lim:mem` and `lim:softmem` are now in GB, not MB.** `lim:mem` is a hard limit (the
  solution cannot be retrieved if hit); prefer `lim:softmem` (default: no limit).
- `lim:sol`: since Gurobi 14, value 1 no longer triggers additional feasibility
  heuristics; use `mip:focus=1` for that.
- `pre:funcpieces`, `pre:funcpiecelength`, `pre:funcpieceerror`, `pre:funcpieceratio` are
  **deprecated by Gurobi** together with function constraints; nonlinear functions go to
  Gurobi as expression trees (`../mp-library/expressions-and-modeling-guide.md`).
- New: the `mip:plateau:*` plateau-stop family, `mip:basis:timelimit`/`iterlimit`,
  `obj:multi:stats`, `obj:multi:inheritparams`, tuning options (`tech:tunecriterion`,
  `tech:tunemetric`, `tech:tunetargetmipgap`, `tech:tunetargettime`, …), cuts
  `cut:psd`, `cut:strongcg`, `cut:liftproject`, `cut:dualimplied`, `cut:projimplied`.
- Changed defaults: `tech:tunetimelim` 86400 s (was automatic); `tech:tunetrials` 0 =
  automatic (was 3); `bar:crossoverbasis` gains -1 automatic (default); `alg:pdhggpu`
  requires `alg:method=6` and a GPU-enabled build; `iis:method` values redefined (0
  filtering-based, 1 faster LP-based, 2 filtering ignoring bounds).

## See also

- General solver-options mechanics (`(solver)_options` vs. `mp_options`, native
  options, option files): `../mp-library/feature-and-solver-options-guide.md`
- Choosing a solver in the first place: `../core-language/13-solver-selection-guide.md`
- MIP-specific modeling advice (warm starts, gap tolerances in context):
  `../modeling-patterns/integer-programming.md`
