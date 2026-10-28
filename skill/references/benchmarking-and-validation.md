# Trusting Results and Comparing Formulations

Derived from: mp-troubleshooting.md ("Reading solver results", "Comparing formulations
and solvers"), mp-tools-and-details.md ("Before benchmarking a reformulation"),
mp-feature-guide.md (solve result codes), amplpy-best-practices.md (status checks,
Section 11); plus developer field measurements (multi-solver, multi-seed benchmark studies
of MIP, MINLP and NLP reformulations), with the benchmarking literature cited inline. The
rules and the seed/pairing figures (2.4×, 1.4×/1.6×) are in the MP guide; the
bound-vs-incumbent case (objective 0 vs. ~33 460, 367 → 9 disagreements) and the
experimental-design habits are field measurements only.

This is the single home for reading results and comparing runs. Other files point here:
`mp-library/tools-troubleshooting-and-reformulation.md`,
`amplpy/core-workflow-best-practices.md` (the Python code for the checks) and
`modeling-patterns/model-as-evaluator-and-heuristics.md`.

Reformulating a model, choosing a solver, or claiming a heuristic works all rest on
reading solver results correctly and comparing them fairly. Both are easy to get wrong in
ways that produce clean-looking tables. This page collects the checks that caught real
errors. None depends on a particular solver, and all are cheap compared to acting on a
wrong conclusion.

## Table of contents

- What a solver status does and does not claim
- Cross-check every bound against every incumbent
- Validating a reformulation
- Comparing performance fairly
- Experimental design habits
- A run that fails must leave a record
- References
- See also

## What a solver status does and does not claim

- **A local solver's "optimal" is a local claim.** For a local NLP solver, or a MINLP
  solver run in local mode, on a nonconvex model, `solve_result = solved` means a point
  satisfying local optimality conditions, and sometimes only "satisfactory". It is a
  feasible point and an upper bound for minimization, not a proof. Count it as found, not
  as proved. On convex models (LP, convex QP/SOCP, MILP) the same status is a proof.
- **A time-limit stop may return the starting point.** Some solvers, on hitting a limit
  with no improved point, return nothing new, and AMPL keeps the variables' current
  values. The status says `limit` and the variables look like a solution. **Check that the
  point moved:** compare it with the values before `solve`, or check that a solver-reported
  objective was returned. In a loop, treat "did not move" as a failed solve.
- **An "infeasible" claim can be wrong**, especially on nonconvex or numerically difficult
  models, or when a presolve mishandles a construct. Before acting on it, re-solve with a
  second solver, or solve an elastic version (`modeling-patterns/model-as-evaluator-and-heuristics.md`)
  and read which slacks are needed.
- **Check the returned point itself.** Constraint residuals, bound violations and logical
  constraints, via MP's automatic solution check
  (`mp-library/tools-troubleshooting-and-reformulation.md`) or your own residual
  computation. A status with a large residual is not a solution.
- **Do not screen with the reported gap alone.** Reported relative gaps can be wrong on
  correct rows as well as on wrong ones. Recompute the gap from objective and bound where
  you need it.

## Cross-check every bound against every incumbent

When several runs (solvers, seeds, formulations) solve **the same instance**, every
feasible objective found is an incumbent for one problem, and every dual bound bounds the
same optimum. A run that reports "optimal" asserts a bound equal to its objective. So:

> an incumbent better than any run's bound is impossible, and each such pair exposes a
> defect in one of the two runs.

This test needs no extra solving and assumes nothing about which solver is right. Applied
to a large benchmark, it found an "optimal" claim at objective 0 on a maximization whose
proven optimum was about 33 460. The run had a clean solution check, and every other
screen had missed it. Use two thresholds or the test drowns in noise:

- ignore differences below about 1e-9 relative (identical optima differing in the last
  bits);
- ignore differences within the solvers' own optimality tolerance (a proven optimum
  legitimately beaten inside another run's MIP gap).

In one study these two thresholds cut 367 raw disagreements to 9 real ones.

## Validating a reformulation

A new formulation of a model is trusted only after it reproduces the original's results
on identical data:

- **Compare objective and status** against the original, within a small relative
  tolerance (e.g. 1e-4), or check that both hit the same limit status. Do it on at least
  two instance sizes and two solvers. One solver can share a defect with the formulation.
- **Feed every formulation the same data.** Keep the set and parameter names identical so
  one data source serves all of them.
- **Agreement among formulations derived from one another is not validation of the
  problem.** They can agree perfectly and all solve the wrong problem. For the first
  formulation of a new problem, build an independent reference by a different method with
  as little shared machinery as possible: an analytic solution, an enumeration on a tiny
  instance, or a simulation.
- **Make the reference emit a whole solution, not a scalar.** When objectives disagree:
  1. **Check the sign first.** A missing constraint in the model makes the model's
     optimum *better*, not worse, which rules out half the explanations immediately.
  2. **Evaluate the reference's point in the model's own rows.** Fix the variables to it
     and compute every residual. The violated row, index and magnitude usually name the
     bug.
- **After a correction, require more than the disputed number to agree:** the solution
  structure, the active constraints, the dual prices. A fix tuned to hit one objective can
  hit it by accident; hitting the structure too is much stronger evidence.

## Comparing performance fairly

- **Pair on the instance.** Compare times only over instances that both methods solved,
  and report how many those are. A per-method mean over its own solved instances rewards a
  method for failing on the hard ones. Measured, this flipped a conclusion: "1.6× faster"
  unpaired became "1.4× slower" paired, because one side's mean was full of near-instant
  failures.
- **Say "no common instance" instead of printing a ratio** when there is none. Two
  time-limit means divided by each other look like a measurement and are not.
- **Separate the axes.** Instances solved, final gap or bound, and time to proof often
  disagree. Report them separately rather than as one score.
- **Repeat with different random seeds.** MIP and MINLP solve times vary substantially
  under changes that should be neutral, such as the seed or the row order (performance
  variability; Lodi & Tramontani 2013). Measured: a 2.4× speedup seen on one seed
  disappeared over five. Use several seeds per instance and report the spread.
- **Summarize with robust statistics.** Use the shifted geometric mean of times (Achterberg
  2007; Koch et al. 2011) or performance profiles (Dolan & Moré 2002), not the arithmetic
  mean, which a single outlier dominates. Beiranvand, Hare & Lucet (2017) survey good
  practice.
- **Run under the same conditions.** Use the same thread count, the same time limit and
  the same options as the production setting, and the same machine load for every arm of a
  comparison. A solver left to auto-detect threads searches differently from one capped.
  Record solver and driver versions with every result: behaviour changes between versions,
  sometimes under an unchanged version string.

## Experimental design habits

- **Write the prediction down before measuring.** A prediction recorded in advance that
  turns out wrong is the most informative result available, because it exposes a mistaken
  mental model. Several careful a-priori arguments in the studies behind these pages were
  refuted this way.
- **Change one thing per arm.** If an arm changes two things that both plausibly matter
  (say, a tighter constant *and* tighter bounds), add the missing cell of the 2×2 rather
  than arguing about which change did the work.
- **Calibrate instance sizes before validating and benchmarking.** Every number is a
  property of one instance. Recalibrating replaces the instances and silently invalidates
  earlier numbers. Record the instance parameters next to each number.
- **Probe past the comfortable sizes.** Formulation differences often appear only at
  sizes where something stops proving optimality in the time limit. Include at least one
  size where the reference formulation does not finish.
- **Do not let one solver decide a formulation question.** A solver that cannot solve the
  reference formulation tells you nothing about variants of it. A tightening that loses on
  one solver can win on others.

## A run that fails must leave a record

- **Record a failure as a row**, with its status and message, never as a missing result.
  In a log, an absent row is indistinguishable from a success.
- **Check the process outcome, not only Python exceptions.** A solver or the AMPL process
  can die below the interpreter (a crash or a killed process) without a Python traceback.
  Check exit status and output for crash markers, and treat a result that never arrived
  as a failure.
- **Save a reproducer when a solve fails**: the model and data, written with
  `export_model`/`export_data` from a fresh AMPL session holding the same model and data
  (the failed session may not answer). Add the solver options and version. A failure
  without a saved instance cannot be investigated or reported.

## Further reading

The MP modeling guide has the same checks in condensed form,
https://mp.ampl.com/modeling-troublesh.html (sections "Reading solver results" and
"Comparing formulations and solvers"). Notebooks that compare formulations with root
bounds: https://colab.ampl.com/tags/formulation-comparison.html.

## References

- Achterberg, T. (2007). *Constraint Integer Programming*. PhD thesis, TU Berlin
  (shifted geometric mean for solver benchmarking).
- Beiranvand, V., Hare, W., Lucet, Y. (2017). Best practices for comparing optimization
  algorithms. *Optimization and Engineering* 18, 815–848.
- Dolan, E.D., Moré, J.J. (2002). Benchmarking optimization software with performance
  profiles. *Math. Programming* 91, 201–213.
- Koch, T. et al. (2011). MIPLIB 2010. *Math. Programming Computation* 3, 103–163.
- Lodi, A., Tramontani, A. (2013). Performance variability in mixed-integer programming.
  *INFORMS TutORials in Operations Research*. doi:10.1287/educ.2013.0112.

## See also

- `modeling-patterns/choosing-formulations.md` — cheap checks before a benchmark
  (does the construct bind, root bounds, exported model)
- `modeling-patterns/model-as-evaluator-and-heuristics.md` — elastic diagnosis, the
  status-quo baseline
- `mp-library/tools-troubleshooting-and-reformulation.md` — automatic solution checking
  and reading tolerance-violation warnings
- `core-language/11-solver-interaction-and-suffixes.md` — `solve_result` and status codes
- `amplpy/core-workflow-best-practices.md` — batch solving, and failure handling in loops
