# KNITRO Options

Derived from: knitro-asl-options.md, mp-tools-and-details.md (MP2NL invocation)

Source: `raw/knitro-asl-options.md` (`https://dev.ampl.com/solvers/knitro/options.html`),
current as of 2026-10-28 (258 keywords). Knitro's AMPL driver is **not** MP-based; MP's reformulations reach it through the
MP2NL bridge built into the driver (`mp2nl=1`, per the MP documentation). **This is a
curated subset**; see the raw source for every keyword.

Knitro solves smooth NLP and MINLP to **local** optimality (on nonconvex models it can be
combined with multistart, below); it handles complementarity constraints natively
(`../core-language/13-solver-selection-guide.md`).

**Flag:** the option list on the Knitro page does not include `mp2nl` itself, while the
MP documentation (`../mp-library/tools-troubleshooting-and-reformulation.md`) and the
solvers index document `knitro_options 'mp2nl=1'`. If your installed driver rejects it,
call MP2NL explicitly (`solver=mp2nl`, `mp2nl_options='solver=knitro'`).

## Setting options

```ampl
option solver knitro;
option knitro_options 'outlev=1 maxtime=300 mp2nl=1';
solve;
```

With `mp2nl=1`, MP's own options (`cvt:...`, `sol:chk:...`) go through the AMPL option
`mp_options`, not `knitro_options` (`mp2nl-options.md`). Many older keywords are marked
**deprecated** in favour of new names: `alg`/`algorithm` → `nlp_algorithm`;
`maxtime_cpu`/`maxtime_real`/`mip_maxtime_*`/`ms_maxtime_*` → `maxtime`;
`threads`/`par_numthreads` → `numthreads`; `mip_integral_gap_*` → `mip_opt_gap_*`;
`feastolabs`/`opttolabs` → `feastol_abs`/`opttol_abs`; `pivot` → `linsolver_pivottol`.

## Verbosity

`outlev`: 0 none, 1 summary, 2 every 10 iterations, 3 each iteration, 4 with function
counts, 5 with the solution vector, … `mip_outlevel` and `mip_outinterval` for the MIP
log; `timing` (0–3) for I/O and solve times.

## Algorithm

`nlp_algorithm`: 0 automatic, 1 interior/direct, 2 interior/CG, 3 active-set SLQP, 4
active-set SQP, 5 several algorithms (possibly in parallel), 6 augmented Lagrangian.
`hessopt` chooses exact Hessians (1) or a quasi-Newton approximation (2 BFGS, 3 SR1, 6
L-BFGS with `lmsize`, …). `bar_murule` sets the barrier-parameter rule; `convex` (-1 auto,
0 no, 1 yes) declares convexity; `presolve` (0/1) the Knitro presolver.

## Stopping and tolerances

| Keyword | Effect |
|---|---|
| `maxtime` | Real-time limit in seconds |
| `maxit` | Iteration limit |
| `feastol`, `feastol_abs` | Relative / absolute feasibility stopping tolerance |
| `opttol`, `opttol_abs` | Relative / absolute KKT (optimality) stopping tolerance |
| `infeastol` | Tolerance for declaring infeasibility |
| `mip_opt_gap_rel`, `mip_opt_gap_abs` | MIP gap stop tolerances |
| `mip_maxnodes` | MIP node limit (0 = no limit) |
| `mip_integer_tol` | Integrality threshold |

`soltype`: 0 return the final iterate, 1 return the best feasible iterate found.
`honorbnds` (-1 auto, 0 allow violating bounds, 1 always enforce, 2 only at the initial
point).

## Nonconvex models: multistart

`ms_enable=1` solves from multiple start points to find a better local minimum;
`ms_maxsolves`, `ms_numthreads`, `ms_seed`, `ms_maxbndrange` (range for unbounded
variables), `ms_terminate`; `mip_multistart` does the same at the branch-and-bound level.
None of this proves global optimality (`../benchmarking-and-validation.md`).

## MIP

`mip_method`: 0 auto, 1 branch and bound, 3 mixed-integer SQP. `mip_branchrule` (1 most
fractional, 2 pseudocost, 3 strong), cuts (`mip_gomory`, `mip_mir`, `mip_knapsack`,
`mip_clique`, `mip_zerohalf`, `mip_liftproject`, `mip_cut_flowcover`), heuristics
(`mip_heuristic_strategy`, `mip_heuristic_feaspump`, `mip_heuristic_lns`, …),
`mip_numthreads`.

## Tuner and threads

`tuner=1` runs the Knitro-Tuner (`tuner_optionsfile`, `tuner_maxtime_real`,
`tuner_terminate`). `numthreads` sets threads for the parallel features.

## See also

- `ipopt-options.md` — the open-source local NLP solver
- `mp2nl-options.md` — reaching Knitro through MP's reformulations
- `../modeling-patterns/complementarity-problems.md`
- Exhaustive keyword list: `raw/knitro-asl-options.md`
