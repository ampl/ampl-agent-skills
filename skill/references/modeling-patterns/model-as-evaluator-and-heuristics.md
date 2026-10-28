# The Model as an Evaluator: Fix-and-Solve, Baselines, Relax-and-Round

Derived from: amplpy-best-practices.md (Section 4 "Modify the model, not only the data",
Section 11 "Iterative algorithms and long runs"), basic-scripting.md / ampl-book.md ch. 11
(`fix`, `drop`, `let`); plus developer field measurements (an NLP-based heuristic for
discrete-control scheduling on public power-network benchmarks, and MINLP benchmark
studies), with the published literature cited inline. The one-evaluator, elastic-ranking
and status-quo rules are also stated in the amplpy best-practices page; the measured
figures (88 % of runs, uniform relaxed weights, entropy) are field measurements only.

When the full mixed-integer model is too hard to solve directly, a common and effective
design keeps the AMPL model and **uses it as an evaluator**: a heuristic proposes values
for the discrete decisions, the decisions are fixed, and the solver optimizes or
simulates the continuous rest. AMPL makes this cheap: `fix`/`unfix`, `drop`/`restore`,
`let`, named problems, and amplpy for the loop. This file is about doing it soundly.

## Table of contents

- Terminology used here
- Fix the decisions, solve the rest
- One evaluator, and an objective you can recompute
- Rank infeasible candidates instead of discarding them
- Always compare against a do-nothing baseline
- Rolling horizon: windows on one model
- Relax-and-round: check the relaxation says something first
- References
- See also

## Terminology used here

| Term | Meaning |
|---|---|
| **fixed-integer subproblem** | the continuous problem left when all discrete variables are fixed (the "NLP subproblem" of outer approximation, Duran & Grossmann 1986) |
| **evaluator (oracle)** | the procedure that turns a candidate decision into a value: here, a solve of the fixed-integer subproblem |
| **sequential simulation** | evaluating a schedule period by period, each period starting from the previous one's state |
| **elastic formulation / exact penalty** | constraints made soft with nonnegative slacks priced by a large linear (L1) penalty; for a large enough price the optimum of the penalized problem is the original optimum (Fletcher 1987) |
| **baseline** | the reference a heuristic must beat; the *status-quo* (do-nothing) baseline keeps every discrete decision at its current state |
| **rolling horizon** | optimizing a window of periods with the rest fixed, then moving the window |
| **relax-and-round / RENS** | solve the continuous relaxation, then round or fix variables near integral values (RENS: search the neighborhood the relaxation defines, Berthold 2014) |
| **relax-and-fix** | solve with integrality enforced only in the current window, fix that window, move on |

## Fix the decisions, solve the rest

```ampl
# candidate tap positions from the heuristic, then evaluate
let {k in DEVICES, t in T} Pos[k,t] := cand[k,t];
fix {k in DEVICES, t in T} Pos[k,t];
solve;                          # the solver sees a continuous problem
# ... read the result, then release for the next candidate
unfix {k in DEVICES, t in T} Pos[k,t];
```

AMPL's presolve removes fixed variables, so a model whose only nonlinearity is a product
of a discrete and a continuous variable becomes linear in the continuous part once the
discrete part is fixed. With every control fixed, many physical models reduce to an
equation system (a power flow, a network hydraulics solve) or to a small NLP. That is
much cheaper than the MINLP and needs only a local solver.

Three practices made the evaluations trustworthy:

- **Chain sequential periods.** For time-coupled physics, evaluate period `t` from the
  solution of period `t-1` (state carried over, variables warm-started). Evaluating every
  period from the same nominal start gives different, and sometimes infeasible, answers.
- **Start from a consistent point.** Solve the fixed system once and start the
  optimization from its solution (`nlp-formulation-choices.md`, "Starting points").
- **Search in a smooth model, report in the exact one.** If the exact law is nonsmooth,
  evaluate candidates in a smoothed version and re-evaluate the final one exactly
  (`nlp-formulation-choices.md`, "Smooth stand-ins").

## One evaluator, and an objective you can recompute

- **Use one evaluator for every comparison.** Two candidates valued by different
  procedures (one by an NLP re-solve, one by a fixed simulation, or with different
  tolerances) cannot be ranked. Changing the evaluator mid-study silently invalidates
  earlier comparisons. Re-score the old results with the new evaluator before comparing.
- **Recompute the objective outside the solver.** From the returned point, compute the
  reported objective with independent code or an AMPL expression, and require a match.
  This catches sign conventions, terms the solver dropped, and penalty slacks counted as
  cost.
- **Check every returned point**, not only the status: constraint residuals, bounds, and
  that the point moved from the start (`../benchmarking-and-validation.md`).

## Rank infeasible candidates instead of discarding them

A heuristic needs to compare candidates that are all infeasible, especially early on. An
infeasible solve gives no ranking. An elastic version of the same model does:

```ampl
param elastic binary default 0;
param pen default 1e3;                      # large compared to objective terms
var SlackUp {i in BUS, t in T} >= 0;
var SlackDn {i in BUS, t in T} >= 0;

# two rows: a double inequality may not have variables in its outer terms
subject to VoltLo {i in BUS, t in T}: V[i,t] >= vmin[i] - (if elastic then SlackDn[i,t]);
subject to VoltHi {i in BUS, t in T}: V[i,t] <= vmax[i] + (if elastic then SlackUp[i,t]);

minimize Total: Cost + (if elastic then
   pen * sum {i in BUS, t in T} (SlackUp[i,t] + SlackDn[i,t]));
```

With `elastic = 1` every candidate gets a value. A feasible candidate has zero slack, and
with a large enough `pen` the elastic problem has the same optimum as the original (exact
L1 penalty, Fletcher 1987). Elastic mode is how active-set NLP solvers recover from
infeasible subproblems (Gill, Murray & Saunders 2005). Two uses:

- **Ranking**: total violation first, objective second.
- **Diagnosis**: the slacks that are nonzero name the rows, indices and magnitudes that
  make a candidate infeasible. This is usually more informative than an infeasibility
  certificate. After fixing that cause, re-solve the exact model.

Report only exact-model results. An elastic value is a ranking device, not an answer.

## Always compare against a do-nothing baseline

The obvious baseline is the current (entering) state: change nothing, evaluate. A
stronger and often overlooked one is the **status-quo optimum**: hold every discrete
decision at its current value and optimize only the continuous layer. Set-points,
dispatch and flows still move; no discrete device moves.

Measured on a discrete-control scheduling heuristic: before a defect in the heuristic was
found, this baseline beat it on about 88 % of runs. Every earlier comparison had been
against the raw entering state, which the heuristic beat comfortably. The defect was that
the search never moved a device at all, and the status-quo baseline is what exposed it.

So report three numbers: the entering state, the status-quo optimum, and the method. The
improvement worth claiming is the method over the status-quo optimum. A heuristic that
does not beat it is not yet earning its discrete moves.

## Rolling horizon: windows on one model

A rolling horizon solves a window of periods with the past and future fixed, then moves
on. In AMPL this needs no second model:

```ampl
param w_start; param w_end;
set WIN := w_start..w_end;

fix {k in DEVICES, t in T: t < w_start or t > w_end} Pos[k,t];
drop {t in T: t > w_end} PeriodRows[t];      # rows of periods outside the window
solve;
restore {t in T: t > w_end} PeriodRows[t];
unfix {k in DEVICES, t in T} Pos[k,t];
```

Points to settle explicitly:

- **What crosses the window boundary**: storage levels, switching counts, ramp limits.
  These need the fixed neighbours' values, or a terminal condition.
- **What a window may change**: one position per device for the whole window searches far
  less (`positions^devices`) than one per device and period (`positions^(devices ×
  periods)`). That restriction is easy to introduce unnoticed. Write the search space down.
- **The final answer is a whole-horizon evaluation**: after the last window, evaluate the
  full horizon once with the chosen decisions fixed, and report that. Per-window
  objectives do not sum to it when windows interact.

Related standard methods: relax-and-fix (integrality only in the current window),
fix-and-optimize, and local branching (Fischetti & Lodi 2003), which limits how many
discrete variables may change from the incumbent.

## Relax-and-round: check the relaxation says something first

Relaxing integrality and rounding the result (or fixing the variables that came out
integral, as in RENS) works when the relaxation has an opinion. It can fail to have one
in a way that looks like success:

- A discrete position was modelled as a one-hot choice among `n` positions (binary
  `Y[k,p]`, position `= sum {p} p*Y[k,p]`). On a ladder symmetric around the current
  position, the relaxed weights came back **uniform**: 1/25 on each of 25 positions.
  Their weighted mean was exactly the current position, and was "integral".
- The cause was structural, not numerical. The move cost was charged on the scalar
  position, and the physics used the weighted blend of coefficients. The relaxation could
  therefore blend all positions at zero move cost, and did.
- So every rounding rule (round the mean, fix if near-integral, pick the two neighbours of
  the mean) returned "do not move", and the heuristic never moved a device.

**Measure the relaxation's concentration before trusting it.** For each discrete
quantity, compare the largest relaxed weight with uniform (`max_p Y[k,p] × n`: 1 means no
opinion, `n` means decided), or compute the weights' entropy against its maximum.
Measured: 88–99 % of maximum entropy across networks; not one of 248 devices decided.
When most quantities are near uniform:

- do not round. Fall back to a neighborhood search (e.g. ±1 step in random order);
- take candidates from the **support** of the relaxed weights, not from the neighbours of
  their weighted mean;
- consider pricing the move on each position's weight rather than on the blended scalar,
  so the relaxation pays for blending.

The same check applies to any relaxation-guided method: RENS, relax-and-fix, or
relaxation-based branching scores. An integral-looking relaxed value is evidence of a
decision only if the underlying weights are concentrated.

## Worked example

A runnable notebook with the evaluator, the three checks, elastic ranking and the
baselines: https://colab.ampl.com/tags/fix-and-solve.html.

## References

- Berthold, T. (2014). RENS: the optimal rounding. *Math. Programming Computation* 6(1),
  33–54.
- Duran, M.A., Grossmann, I.E. (1986). An outer-approximation algorithm for a class of
  mixed-integer nonlinear programs. *Math. Programming* 36, 307–339.
- Fischetti, M., Lodi, A. (2003). Local branching. *Math. Programming* 98, 23–47.
- Fletcher, R. (1987). *Practical Methods of Optimization*, 2nd ed., ch. 12 (exact
  penalty functions). Wiley.
- Gill, P.E., Murray, W., Saunders, M.A. (2005). SNOPT: an SQP algorithm for large-scale
  constrained optimization. *SIAM Review* 47(1), 99–131 (elastic mode).

## See also

- `../core-language/08-commands-modifying-models-and-data.md` — `fix`/`unfix`,
  `drop`/`restore`, `let`
- `../core-language/11-solver-interaction-and-suffixes.md` — named problems and
  `solve_result`
- `../amplpy/core-workflow-best-practices.md` — driving such loops from Python, including
  the "Iterative algorithms" section
- `nlp-formulation-choices.md` — starting points and smoothing used inside the evaluator
- `../benchmarking-and-validation.md` — checking each returned point and comparing methods
  fairly
