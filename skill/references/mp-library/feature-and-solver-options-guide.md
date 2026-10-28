# Feature and Solver Options Guide for MP-Based Solvers

Derived from: mp-feature-guide.md, mp-plateau-stop-theory.md

Source: `mp-feature-guide.md` (`https://mp.ampl.com/features-guide.html`).

MP defines a set of standard *solver features* — capabilities characterized by a set of
options, sometimes AMPL suffixes for input/output data, and a defined effect on the
solution process. Because these are defined once at the framework level
(`overview-and-when-to-use.md`), option names and semantics are consistent across every
MP-based solver that implements a given feature, even though not every solver implements
every feature (see "Support by solvers" below). **For actually tuning a specific solver**
(which algorithm to pick, autotuning, branching strategy, cut generation, and other
solver-specific knobs) **see `../solver-options/`** — this file covers the
cross-solver mechanics and the common features MP standardizes, not per-solver tuning
advice, to avoid duplicating that content here.

## Important features at a glance

| Feature | Key option(s) |
|---|---|
| **Limits and gaps** | `lim:time` (`timelimit`); `lim:soltime` (Xpress, COPT: limit once a feasible solution is found); `mip:gap`, `mip:gapabs` (`mipgap`, `mipgapabs`); `mip:return_gap`, `mip:bestbound` report the final gap and dual bound; plateau stop (below) |
| **Algorithm and search** | `alg:method` (LP/QP and the MIP root relaxation); `mip:nodemethod` (Gurobi, CPLEX, MOSEK); `bar:crossover` (MOSEK `bar:basis`); `tech:threads`, `tech:seed` (compare formulations over several seeds); `alg:start` warm start; `alg:basis`, `mip:basis`; `alg:relax` (relaxes integrality *after* MP's reformulation — unlike AMPL's `relax_integrality`, which relaxes before MP); search emphasis, solver-specific: `mip:focus` (Gurobi; CPLEX `mip:emphasis`), `mip:heuremphasis` (Xpress), `mip:norelheurwork` (Gurobi), `alg:solutiontarget`/`alg:optimalitytarget` (Gurobi; CPLEX `qp:target`) |
| **Numerics and tolerances** | `alg:feastol`, `mip:inttol`; `lp:opttol` (Gurobi, Xpress, CPLEX); `pre:solve`, `scale`; `alg:numericfocus` (Gurobi, Xpress, CPLEX), `mip:intfocus` (Gurobi), `alg:refineops` (Xpress) — see `efficiency-and-numerical-accuracy.md` |
| **Reformulation** | `cvt:bigM` (universal bound for variables in logical expressions that have none); `acc:...` (what the solver receives natively) and `cvt:...` (how MP reformulates) — `tools-troubleshooting-and-reformulation.md`; AMPL option `pl_linearize=0` recommended |
| **Checking and inspecting** | `tech:outlev`, `tech:timing`; automatic solution check `sol:chk:...`; model export `tech:writeprob`, solution export `tech:writesolution` (`writesol`); infeasible models: `iis:find`, `alg:feasrelax` |
| **Several solutions and objectives** | `sol:stub`, `sol:count`, `sol:poollimit`; `obj:multi` (`multi-objective-optimization.md`), `obj:no` selects one objective |
| **Options for all MP solvers** | AMPL option `mp_options` (read before `<solver>_options`); `tech:optionfile` |
| Plateau stop (stall-based MIP termination) | `mip:plateau:time`, `mip:plateau:abstol`, `mip:plateau:reltol`, `mip:plateau:warmup`, `mip:plateau:log`, plus gap-based variants below |

## How AMPL/MP solver options work

### `<solver>_options` and `mp_options`

Solver-specific options are set via `<solvername>_options` (or, if the executable has been
renamed, e.g. `gurobi25.exe`, the matching `gurobi25_options`):

```ampl
option solver gurobi;
option gurobi_options 'iis=1';         ## Tell Gurobi to find IIS
solve;
```

Options common to **all** MP solvers can instead be set once via `mp_options`:

```ampl
option mp_options 'lim:time=300';      ## Applies to every MP solver
```

`mp_options` is parsed *before* `<solvername>_options`, so it sets a baseline that the
solver-specific string can then override for that one solver.

From the command line, options can go through an environment variable or as trailing
arguments:

```
mp_options='outlev=1 tech:writeprob=model.mps' gurobi.exe model.nl   # Method 1
gurobi.exe model.nl outlev=1 tech:writesol=model.sol                  # Method 2
```

### Listing and querying options

`<solver> -=` lists every available option; `<solver> -=key` filters to options containing
`key`:

```
$ highs -=acc:
acc: Options:

acc:linrange (acc:linrng)
    Solver acceptance level for 'LinConRange', default 2
```

The full option list per solver is also published at AMPL Development
(`https://dev.ampl.com/solvers/index.html`).

Query an option's current (default or previously set) value with `?`:

```ampl
option mosek_options 'threads=?';
solve;
## MOSEK 11.2.0:   tech:threads = 0
```

### Option files and native options

An option file can be loaded via `tech:optionfile`:

```ampl
option cbc_options 'optionfile="options_experiment1.txt"';
```

Some solvers also accept **native** (solver's own, non-AMPL-standardized) option names,
via `tech:optionnative`, alongside the standard AMPL/MP name for the same setting:

```ampl
option gurobi_options 'alg:numericfocus 3';                    ## standard AMPL/MP name
option gurobi_options 'tech:optionnative "NumericFocus 3"';    ## native Gurobi name
gurobi.exe model.nl optnative="numericfocus 2" optnative="Seed 500"   # from command line
```

`tech:optionnativeread`/`tech:optionnativewrite` read/write native options from/to a file,
for solvers that support it.

## Solve result codes

`solve_result_num`/`solve_result` report the outcome of the last solve
(`../core-language/11-solver-interaction-and-suffixes.md` covers the mechanism itself);
MP standardizes the numeric ranges across solvers:

| Range | Meaning |
|---|---|
| 0–99 | solved: optimal (or feasible, for a satisfaction problem) |
| 100–199 | solved?: solution candidate returned but error likely (150 specifically = MP solution check failed, `sol:chk:fail`) |
| 200–299 | infeasible |
| 300–349 | unbounded, feasible solution returned |
| 350–399 | unbounded, no feasible solution returned |
| 400–449 | limit, feasible: stopped early (iterations, time, Ctrl-C, ...) |
| 450–469 | limit, ambiguous: problem is either infeasible or unbounded — disable dual reductions or run the IIS finder for a definitive answer |
| 470–499 | limit, no solution returned |
| 500–999 | failure, no solution returned (550 specifically = numeric issue, no feasible solution) |

Individual solvers add more specific codes within these ranges; list them with `<solver>
-!` from the command line (e.g. `shell "mosek -!";` from within AMPL) or look them up at
AMPL Development.

## Support by solvers (condensed)

Legend: ✅ native, ✓ emulated (MP provides the behavior even though the underlying solver
doesn't), ❌ not supported. From the page's table as of 2026-10-28.
For MP2NL, features also depend on the subsolver.

| Feature | Copt | CPLEX | Gurobi | Mosek | Xpress | CBC | GCG | HiGHS | SCIP | CPSAT | cuOpt | BaronMP | MP2NL |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Model export | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ |
| Solution export | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ |
| Report solution time | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Feasibility Relaxation | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Irreducible Inconsistent Subset (IIS) | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Input and output basis | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Kappa | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Multiple solutions | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ | ✅ | ❌ |
| Multiple objectives | ✅ | ✅ | ✅ | ✓ | ✅ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Sensitivity analysis | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Unbounded rays | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Warm start | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ |
| Fixed model (return basis for MIP) | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Lazy constraints and user cuts | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Return MIP gap | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Return best dual bound | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Variable priorities | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Plateau stop (stall-based MIP termination) | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Plateau stop including MIP gap progress | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |

Changes since the August 2026 version of this table: solution export added for COPT,
MOSEK, GCG and SCIP; feasibility relaxation and IIS for HiGHS (IIS also SCIP);
sensitivity analysis for COPT, CPLEX and HiGHS; warm start for SCIP; fixed model for COPT,
MOSEK, HiGHS and SCIP (emulated, see below); lazy constraints for COPT; GCG lost input/
output basis. CP-SAT, cuOpt, BaronMP and MP2NL columns are new.

## General features

Each entry below: what it's for, the controlling option, and one example. Option/suffix
names are standardized across MP solvers per the "consistency" goal in
`overview-and-when-to-use.md`.

- **Output level** (`outlev`) — how much solver log output to print; `0` (default,
  suppressed — only the terminal `solve_message` shows), `1` detailed log, `2`+
  solver-dependent verbosity. `option solver_msg 0;` suppresses even the `solve_message`
  (the banner still prints; redirect `solve > NUL;` to suppress that too).
  `option <solver>_options 'outlev=1';`
- **Model export** (`writeprob`) — export the model before solving, format inferred from
  the file extension: `option <solver>_options 'writeprob=/tmp/diet.lp';`. Set
  `<solver>_auxfiles rc` (or `auxfiles rc` before `write`) first to carry variable/
  constraint/objective names into the export. In AMPL itself, `expand ConName;` shows the
  expanded constraint, and `solexpand;` shows the full AMPL-presolved model as sent to the
  driver (`option presolve 0;` first to see it without AMPL's own presolve applied).
- **Solution export** (`tech:writesolution`, `writesol`) — write the solution in the
  solver's own format (e.g. to compare with a run outside AMPL, or attach to a support
  request); the file extension may select among formats, and the option can be repeated:
  `option <solver>_options 'writesol=/tmp/diet.sol';`
- **Report solution time** (`tech:timing`/`tech:reporttimes`) — `0` off (default), `1`
  reports `time`, `time_setup`, `time_solver` suffixes on the problem, `2` adds
  `time_read`, `time_conversion`, `time_output`. `option <solver>_options 'timing=1';`
- **Warm start** (`alg:start`) — use incoming variable values (and, for LP, dual values) to
  start the algorithm instead of from scratch. `0` no, `1`–`3` yes with varying basis
  interaction (`3` = default: use incoming basis too, if any). Applicability: LP and MIP.
  When comparing formulations or solvers, give every run the same starting values derived
  from the data, never from a solve of the same model (`../benchmarking-and-validation.md`).
- **Input/output basis** (`alg:basis`) — pass/return a simplex basis via `status` suffixes
  on variables and constraints; `3` (default) does both. Re-solving with a sent basis can
  cut solve time to near zero for a marginally changed model.
- **Feasibility relaxation** (`alg:feasrelax`) — find a feasible solution to an infeasible
  model by allowing bound/constraint violations, penalized in the objective. Penalty
  weights: macro options `alg:lbpen`/`alg:ubpen`/`alg:rhspen` (default 1 each) or
  per-entity suffixes `lbpen`/`ubpen`/`rhspen` (default 0, meaning "use the macro
  default"); a negative penalty means "never violate this one." Values `1`–`3` choose the
  objective (weighted sum / weighted sum of squares / weighted count of violations), `4`–`6`
  add "and still optimize the original objective, subject to the violation being
  minimized." Applicability: LP and MIP.

  ```ampl
  option <solver>_options "alg:feasrelax=1"; option presolve 0;
  solve; display x, y;
  ```
- **Multiple solutions** (`sol:stub`, `sol:count`, `sol:poollimit`) — enumerate alternative
  (sub-optimal, for MIP) solutions found during search. Setting `sol:stub` auto-enables
  counting; solutions land in `<stub>1.sol` ... `<stub><nsol>.sol`, with `nsol`/`npool`
  reported as problem suffixes. `sol:poollimit` caps how many are kept.
- **Sensitivity analysis** (`alg:sens`) — ranges over which the optimal basis stays optimal.
  Output suffixes: `sensobjlo`/`sensobjhi`/`sensobj` (variables), and
  `senslblo`/`senslbhi`/`sensublo`/`sensubhi` (variables and constraints). LP and MIP.
- **Kappa** (`alg:kappa`) — condition number of the current LP basis matrix (stability
  measure); only available for a basic solution (barrier without crossover won't have
  one). `1` reports it in `solve_message`, `2` returns it in suffix `kappa` (on objective
  and problem).
- **Unbounded rays** (`alg:rays`) — for unbounded/infeasible linear models, return the
  direction of unboundedness (`unbdd` suffix on variables) or the infeasibility
  certificate (`dunbdd` suffix on constraints); `3` (default) returns both.
- **Multiple objectives** (`obj:multi`) — `0` off (default, only first/`obj:no` objective
  considered), `1` native if available else emulated, `2` always emulated. Full treatment:
  `multi-objective-optimization.md`.
- **IIS** (`alg:iisfind`/`iisfind`/`iis`) — for an infeasible model, find an Irreducible
  Inconsistent Subset: a minimal set of constraints/bounds that's still infeasible.
  `1` on; output is suffix `iis` (value `mem` for members) on variables and constraints.

## MIP-only features

- **Return MIP gap** (`mip:return_gap`) — `absgap = |objective - bestbound|`, `relmipgap =
  absgap / |objective|`. Sum of: `1` return `.relmipgap`, `2` return `.absmipgap`, `4`
  suppress gap text in `solve_message`. Gap suffixes report `+Infinity` if no
  integer-feasible solution exists yet.
- **Return best dual bound** (`mip:bestbound`) — `1` returns suffix `bestbound` on the
  objective (the best proven bound; `-Infinity`/`+Infinity` for min/max if unavailable).
- **Lazy constraints and user cuts** (`mip:lazy`) — reads suffix `lazy` on constraints:
  positive marks a lazy constraint (pulled in and enforced only once a candidate solution
  violates it — can cut off integer-feasible points), negative marks a user cut (pulled in
  to strengthen the relaxation, but redundant for integer feasibility). `3` (default)
  accepts both signs.
- **Variable priorities** (`mip:priorities`) — reads suffix `priority` on variables to
  guide branching order. `1` (default) read them, `0` ignore.
- **Fixed model / basis for MIP** (`mip:basis`) — after solving a MIP, fix all
  integer/SOS-constrained variables at their optimal values and resolve the continuous
  relaxation to obtain a basis, duals, and (if requested) sensitivity ranges that aren't
  otherwise available for MIP. `1` on; outputs constraint dual values and `sstatus` on
  variables and constraints. COPT, MOSEK, HiGHS and SCIP **emulate** it for linear
  algebraic models: all integer columns are fixed to an integer-feasible incumbent (not
  necessarily proven optimal) and a separate continuous model is solved; SOS,
  piecewise-linear, logical and nonlinear inputs are not supported by the emulation. Duals
  describe the fixed continuous problem and are **not MIP shadow prices**; basis statuses
  can differ across solvers. The
  MIP status, bounds, gaps, pool and statistics are kept; if the fixed solve succeeds the
  reported primal values are the fixed solution's (continuous variables may move), if not
  the MIP solution is retained. `mip:basis:timelimit` and `mip:basis:iterlimit` (default
  -1, solver defaults) limit the supplementary solve; for emulation, 0 skips it.
- **Plateau stop** (`mip:plateau:time`, `mip:plateau:abstol`, `mip:plateau:reltol`,
  `mip:plateau:warmup`, `mip:plateau:log`) — stop the MIP search once the incumbent has
  stopped improving by at least `abstol` (absolute) or `reltol` (relative) for
  `mip:plateau:time` seconds, after an initial `mip:plateau:warmup`-second grace period.
  `mip:plateau:time=0` (default) disables the feature entirely. **`abstol`/`reltol`
  combine with OR, not AND** — since `abstol` defaults to 0 ("any change counts"), setting
  only `reltol` has no effect until `abstol` is also raised above the noise floor you want
  to ignore, because any nonzero absolute change already satisfies the OR.

  ```ampl
  option <solver>_options "mip:plateau:time=30 mip:plateau:abstol=1e-6 mip:plateau:reltol=0.001";
  solve;
  ```

  Stops if the incumbent hasn't improved by ≥0.1% (or, failing that, ≥1e-6 absolute) for
  30 seconds. `mip:plateau:log=1` prints a per-callback status line
  (`current=... previous=... progress=... elapsed=...`).

  For solvers that also report live MIP gap from the native callback,
  `mip:plateau:absgaptol`/`mip:plateau:relgaptol` add a second, independent progress
  channel — the shared timer resets if *either* the incumbent or the gap makes sufficient
  progress (opt-in: both default to 0, meaning that channel isn't tracked at all, unlike
  `abstol`/`reltol`'s "0 means any change counts"). The matching
  `mip:plateau:warmup:relgap`/`mip:plateau:warmup:absgap` let the warmup grace period end
  early once the reported gap first crosses one of these thresholds, instead of waiting
  out the full time-based `mip:plateau:warmup`. All four options, and the feature itself,
  only apply to solvers that support gap-based plateau stopping (see the support table
  above).

  **How the stopping rule works** (from the MP page "Plateau-based MIP stopping:
  theoretical description"): the driver keeps a baseline value and the time of the last
  *qualifying* report. A new incumbent counts as progress only if it beats the baseline by
  more than `abstol` **or** by more than `reltol` relative to the baseline (with a zero
  baseline, any nonzero change counts under the relative test); only then do the baseline
  and the clock move. A report that does not clear the tolerance is absorbed — it neither
  moves the baseline nor resets the clock, so a stream of tiny improvements cannot keep
  the search alive. The search stops once the warmup is done and `plateau:time` seconds
  have passed since the last qualifying report; the rule is checked on each report, not on
  a separate timer. The gap channel works the same way on the reported MIP gap. (That page
  uses the alias spellings `mip:plateautime`, `mip:plateauabstol`, …)

## See also

- `overview-and-when-to-use.md` — MP entry point, which solvers are MP-based
- `multi-objective-optimization.md` — full `obj:multi` treatment (blending, priorities,
  per-objective option suffixes)
- `efficiency-and-numerical-accuracy.md` — `cvt:bigM` and the numerical-focus options in
  their formulation context
- `tools-troubleshooting-and-reformulation.md` — `sol:chk:mode`/`chk:mode` and other
  solution-checking options referenced above
- `../core-language/11-solver-interaction-and-suffixes.md` — `solve_result`/
  `solve_result_num` mechanics outside the MP-specific numeric-range standardization
- `../solver-options/` — curated, per-solver option guides for actual tuning (algorithm
  choice, autotuning, branching, cuts) once a solver is chosen; this file intentionally
  does not duplicate that content
