# Choosing Between Formulations: Bounds, Logic, Known Formulations (MIP and logical models)

Derived from: mp-choosing-between-formulations.md, mp-efficiency-considerations.md,
mp-numerical-accuracy.md, mp-expressions-supported.md, mp-tools-and-details.md; plus
developer field measurements (benchmark studies of logical vs. hand-linearized
formulations over scheduling, energy, network-design and disjunctive test problems), with
the published literature cited inline. Figures marked *(field measurement)* appear in no
AMPL documentation page.

The nonlinear side of the same choice (substitute or name, coordinates, redundant convex
rows) is in `nlp-formulation-choices.md`.

AMPL with MP lets you state logic directly (`==>`, `or`, `atmost`, `count`, set
membership, `if-then`), and the alternative is a hand formulation with binaries and big-M
or a published reformulation. Both are exact. They can differ by orders of magnitude in
solve time, and **which one wins is often not predictable from the model text**. This file
collects the rules that held up under measurement, and the checks that tell you, before a
long benchmark, which case you are in. Numbers quoted as "measured" come from such
studies; they illustrate a direction and a size, not a guarantee for your model or solver
version. Most of them are also reported in the MP modeling guide ("Choosing between
formulations"); the ones that are not are marked *(field measurement)*.

## Table of contents

- Terminology used here
- Declared bounds decide the big-M constants
- An indicator constraint is not a strictly better big-M row
- Logic that may not reach the relaxation
- Look for a known formulation before writing big-M
- A tighter formulation is not always a faster one
- Cheap checks before a benchmark
- See also

## Terminology used here

Standard terms (Vielma 2015; Conforti, Cornuéjols & Zambelli 2014; Liberti 2009), used
the same way throughout the skill:

| Term | Meaning |
|---|---|
| **formulation** | one algebraic statement of a problem; many formulations share one feasible set of integer solutions |
| **exact reformulation** | a different formulation with the same optimal solutions (Liberti's "opt-reformulation"); every model in this file's comparisons is one |
| **continuous (LP) relaxation** | the formulation with integrality dropped; its optimum is the **root bound** |
| **strength / tightness** | how close the relaxation is to the convex hull of integer solutions; a *stronger* formulation has a better root bound |
| **big-M constraint** | a constraint switched off by a binary times a constant `M`, e.g. `x <= M*z` |
| **indicator constraint** | a logical implication `z = 1 ==> constraint`, passed to the solver as logic rather than as a big-M row (Bonami et al. 2015) |
| **extended formulation** | a formulation with extra (auxiliary, *lifted*) variables whose projection is tighter than any compact one of similar size |
| **convex hull (Balas) formulation** | the extended formulation of a disjunction that copies (*disaggregates*) variables per branch; the tightest possible, and larger than big-M |
| **declared bound** | a bound written in the `var` declaration (`>= lo, <= hi`) |
| **implied bound** | a bound that follows from other constraints but is not declared |
| **bound tightening** | deriving tighter bounds: *feasibility-based* (FBBT, by propagation) or *optimization-based* (OBBT, by optimizing each variable over a relaxation) |
| **valid inequality / cut** | a constraint satisfied by every integer-feasible point; a *facet* is the strongest possible one |

## Declared bounds decide the big-M constants

When MP converts a logical construct for a solver, it sizes every big-M constant from the
**declared bounds of the variables the construct names**, propagated through the
expression. It does not search other constraints for an implied bound. So a construct
over a quantity with no declared bound gets a loose constant, or an error asking you to
"set bounds on variables participating in logical expressions".

**The remedy: give the quantity a name and declare its real bound.**

```ampl
# Loose: MP can only bound Charge[t]-Discharge[t] by the two variables' boxes
subject to Mode {t in T}:
   Charge[t] - Discharge[t] >= 0 ==> Grid[t] >= Charge[t] - Discharge[t];

# Tight: name the difference and declare what the physics allows
var Net {t in T} >= -pmax_dis, <= pmax_ch;
subject to Net_Def {t in T}: Net[t] = Charge[t] - Discharge[t];
subject to Mode {t in T}: Net[t] >= 0 ==> Grid[t] >= Net[t];
```

The same applies to scheduling (declare start times on their earliest/latest-start window
`[est[j], lst[j]]`, not on `[0, horizon]`) and to network flows (declare a flow on its
capacity even when a separate constraint already says so).

Measured, on the same solver and data, changing only declarations *(field measurement)*:

- battery storage scheduling: a time-limit stop at 0.18 % gap became a proof in 12 s;
- job-shop scheduling: 3.2× faster with start-time windows declared;
- staff rostering: a declared per-nurse workload bound 4.5× tighter than the default made it
  10–30 % faster.

Three corollaries:

- **Spend a tightening as a bound, not as a row.** The same physical limit added as an
  explicit constraint (`-d <= Theta[i] - Theta[j] <= d`) was valid, inactive at the
  optimum, and *slowed* the solve. Written as declared bounds on the same quantities it was
  faster. A row on an expression does not reach the big-M sizing; a bound does. A row on
  a *single* variable (`Out[i] <= cap[i]`) is a bound in disguise: AMPL presolve or MP
  turns it into one, so it works as well as the declared bound (measured).
- **Derive the bound from data in closed form.** OBBT (e.g. Coffrin, Hijazi & Van
  Hentenryck 2015 for power networks) produces per-instance numbers. A model file that
  serves many instances needs the algebraic form: derive the bound from the parameters.
  Then run the numerical OBBT once as an *audit* of how much of the available tightening
  the closed form captures. Run that audit **without an incumbent cutoff**: bounds valid
  only over the optimal face are not valid declared bounds.
- **Audit for free variables.** A variable with no bound inside logical or `if`-gated
  content is load-bearing; close it. One that appears only in unconditional rows and the
  objective rarely matters. Close it anyway because the model is then true, but do not
  expect a speedup.

When a hand formulation gets a tighter constant than the logical one, give the logical
model the same fact as a declared bound. Otherwise any comparison between the two
measures the constant, not the formulation.

## An indicator constraint is not a strictly better big-M row

It is tempting to replace every big-M pair by an indicator, since an indicator needs no
constant. Measured, that is a real risk where the big-M constant is honest (derivable
from the data and not grossly loose):

- An electricity-auction model's big-M constant was the full regulated price band, about
  500× wider than the prices that cleared. The prediction, written down before measuring,
  was that indicators would beat it. Instead they were 2.5× slower at the small size, and
  at the medium size they hit the time limit where big-M proved optimality.
- A 2×2 experiment separated the two effects. Tightening the declared bounds halved
  big-M's time and changed the indicator formulation's time by exactly **0 %**. The
  solver branched on the implications as logic; their relaxation strength did not come
  from the bounds.

So:

- **A big-M row with a good constant contributes LP relaxation strength; an indicator
  trades it for exact logic** (Bonami, Lodi, Tramontani & Wiese 2015 analyze this
  trade-off).
- **When an indicator formulation is slow, tightening variable bounds is not the
  remedy.** Find a provably tighter constant (here 4500 → 89, worth 2× on its own) or go
  back to big-M.
- This is not "indicators lose". Equality indicators (`z ==> x = c`) and implications
  whose big-M would be numerically dangerous often win. **Write both and measure.**
- Converting rows to indicators can silently change the formulation family. If the
  conversion forced new disaggregated variables into the model, it is now a different
  formulation and should be compared as one. Diff the column counts.

## Logic that may not reach the relaxation

AMPL transmits `b = 1 ==> C` to the solver as the disjunction `b != 1 or C`. Current MP
versions recover indicator constraints from it, including when the consequent is a
conjunction of comparisons such as a `forall` (option `cvt:pre:disj2ind`). On a unit
commitment test, a minimum up-time written with a `forall` consequent gave **exactly the
same root bound** as one implication per period.

Other logical operators can still reach the solver as native *general constraints* (an
`and`/`or` that is not the consequent of an implication, for example). If neither MP nor
the solver's presolve converts them into linear rows or indicators, they contribute
nothing to the continuous relaxation. Check the root bound rather than assume.

```ampl
# One implication with a conjunction as consequent: may stay a general constraint
subject to MinUp {u in U, t in T}:
   Start[u,t] = 1 ==> forall {s in t..t+minup[u]-1: s in T} On[u,s] = 1;

# Expanded: one implication (or one linear row) per period; reaches the relaxation
subject to MinUp {u in U, t in T, s in t..t+minup[u]-1: s in T}:
   Start[u,t] = 1 ==> On[u,s] = 1;
# ... and for minimum up/down time the known facet-defining form is stronger still:
subject to MinUpRT {u in U, t in T}:
   sum {s in t-minup[u]+1..t: s in T} Start[u,s] <= On[u,t];   # Rajan & Takriti 2005
```

Version note *(field measurement)*: before `cvt:pre:disj2ind`, the compact form's root
bound on a minimum-dwell model was 16.7 % below the optimum (expanded form: 0.14 %). With an
older MP driver, check. The facet-defining form is stronger than both in any version.

The opposite case also occurs. Indicators that presolve **does** linearize back can give
the identical root bound to a hand big-M and still cost far more: in one case 94 071
simplex iterations against 10, and 3.8× the memory. And on a cardinality model the logical
form was the fastest of all, because a binary private to one construct let presolve remove
it entirely. The discriminator is what the solver actually receives, so look at it (see
"Cheap checks" below).

Two related traps:

- **`!=` on a continuous variable is hostage to tolerances.** A variable declared in a
  finite set is still continuous to the solver; count moves of at least half a ladder step
  instead. Details and the corrected `atmost` form: "Counting changes of a continuous
  variable" in `../mp-library/efficiency-and-numerical-accuracy.md`.
- **Set membership vs. an `or`-disjunction is a choice with no known sign.** Writing
  `var X in SOMESET` or `or {k in SOMESET} X = k` gave a 30 % against a 0.05 % gap on one
  model, and the opposite ordering (0.7 % against 2.7 %) on a model of the same shape (a
  factor of 4 to 600 in the remaining gap, as the MP guide puts it). Until MP's set
  membership rework is complete, MP's documentation recommends the disjunctive form
  (`../mp-library/expressions-and-modeling-guide.md`). Try both on your model, and carry
  neither verdict across models.

## Look for a known formulation before writing big-M

A mechanical big-M translation is always available and rarely the best. For common
structures the literature has a better one:

| Structure | Formulation | Reference | When it does not pay |
|---|---|---|---|
| scheduling with start times and resources | time-indexed: binary per (job, start period) | Pritsker, Watters & Wolfe 1969; Sousa & Wolsey 1992 | long horizons with fine time steps (variables grow with horizon length) |
| `alldiff` over a small domain | assignment / exact cover: binary per (item, value), one per item and per value | standard; see Vielma 2015 | domains much larger than the item count |
| semicontinuous variable (`{0} union interval[lo,hi]`) with a convex cost | perspective reformulation (below) | Frangioni & Gentile 2006; Günlük & Linderoth 2010 | linear cost (the fixed charge already is the perspective); concave cost (use a secant inside the disjunct instead) |
| product of a discrete choice and a continuous variable | disaggregate per choice (convex hull of binary × bounded continuous; "edge cloning" in network design) | Glover 1975; Raghunathan 2013 | many choices × many products (size) |
| minimum up/down time | facet-defining window inequalities | Rajan & Takriti 2005 | constraint does not bind (check first) |
| disjunctions in general | convex hull vs. big-M; generalized disjunctive programming | Balas 1985; Grossmann & Trespalacios 2013 | see the next section: the hull's size can cost more than its strength buys |

**The perspective for a piecewise-linear convex cost is linear.** For `f(X) = max_k
(s[k]*X + c[k])` with `f(0) = 0`, paid only while the unit is on (`Z = 1`), multiply each
**intercept** by `Z`:

```ampl
param c {k in 1..nseg} := sum {m in 1..k-1} (s[m] - s[m+1]) * brk[m];  # c[1] = 0
var Cost >= 0;
subject to Persp {k in 1..nseg}: Cost >= s[k]*X + c[k]*Z;
subject to OnOff: lo*Z <= X <= hi*Z;
```

On a convex ladder every `c[k]` (k ≥ 2) is negative, so a fractional `Z` raises the bound.
That is the whole tightening, and it vanishes at integrality. For a quadratic cost the
perspective is a rotated second-order cone, `q*X^2 <= Cost*Z`. Do not convert perspective
rows into indicators (`Z ==> Cost >= s[k]*X + c[k]`): that discards the strengthening.

With MP's semicontinuous declaration `var X in {0} union interval[lo,hi]` there is no `Z`
in the model: gate the intercepts with a threshold inside the gap, `Cost >= s[k]*X + (if X
>= lo/2 then c[k])`. MP decides the comparison with the binary it creates for the
declaration (`cvt:pre:vbnd`), so it is the same perspective, with the same root bound
(measured). On a unit commitment test the perspective closed over 99 % of a 5–6 % root
gap; on the solver used, the plain piecewise-linear form was still the fastest to solve.
Measure the time; the root bound only tells you the tightening is real.

Two habits make this efficient:

- **Do the arithmetic before building.** Count the binaries and rows a known formulation
  needs at your instance sizes. One "better" formulation would have needed 13–22× more
  binaries than the one it was meant to replace, and was ruled out on paper.
- **Keep a facet even in a logical model.** The best formulation of one hydro-scheduling
  problem was a *hybrid*: MP's set-membership declaration for forbidden operating zones,
  plus the published facet inequalities for the dwell times. It beat both the pure logical
  and the pure hand formulation at every size (3.5× at the small size). Restate what MP
  states well, and keep anything the literature has proved strongest. When a hand
  formulation has two separable strong ideas, build the one-change hybrids as additional
  candidates from the start.

## A tighter formulation is not always a faster one

Strength trades against size (Vielma 2015), and the balance shifts with scale and solver:

- **Hull vs. big-M crossed over with instance size** on the same disjunctive test
  problem: the hull won at moderate size and lost at the larger one.
- **Identical root bounds, opposite winners.** On two catalogue-selection models, big-M
  and the hull had byte-identical root LP bounds. The hull won on one and lost 12 of 12
  comparisons on the other (up to 15×). So the root bound does not predict the winner; the
  difference arises deeper in the tree. Two structural arguments written before measuring
  were both wrong.
- **A valid, exact tightening can remove the slack a solver's primal heuristics were
  using.** Narrowing a variable window exactly helped two solvers and made a third get
  stuck on a worse incumbent. Test a tightening on more than one solver before recording it
  as a loss or a win.
- **Near-integral relaxations come from structure.** When the combinatorial core is, for
  example, set packing on an interval graph (a perfect graph), the LP is already nearly
  tight, and extra formulation machinery earns little.

**The rule is procedural: write both formulations and measure.** Before measuring, make
the comparison fair. Size the big-M honestly, since a hull that beats a deliberately loose
big-M proves nothing. And check that the hull really disaggregates what you think: a hull
whose root bound equals the big-M one deserves a second look.

## Cheap checks before a benchmark

Each costs minutes and has saved long benchmark runs.

1. **Does the construct bind?** Solve once and check the constrained quantity actually
   sits against its limit somewhere. Use two quick tests: perturb the limit (an
   unchanged objective means it is slack), and tabulate where the variable landed relative
   to its allowed regions. **Slack constraints mask each other**: a slack start-up cap made
   a forbidden-zone construct look structurally dead until the cap was tightened. Fix the
   loosest constraint first, then re-check. A slack construct still makes a valid
   formulation comparison (pure formulation cost at a fixed objective). It just does not
   make the instance interesting on that axis.
2. **Compare root bounds.** Solve each formulation with its integrality relaxed and
   compare the relaxation optima. With MP-converted logic use the MP solver option
   `relax=1` (`alg:relax`), which also relaxes the binaries MP creates; AMPL's
   `option relax_integrality 1` relaxes only the model's own integer variables. And read
   the objective the *solver* reports (in `solve_message`): AMPL recomputes the objective
   from the returned values and evaluates `if-then`/`==>` exactly at the fractional point,
   which can exceed the true optimum.

   ```python
   import re
   ampl.solve(solver="highs", highs_options="relax=1 chk:mode=0")
   msg = ampl.get_value("solve_message")
   root_bound = float(re.findall(r"objective ([-+0-9.eE]+)", msg)[-1])
   ```

   On the unit-commitment model of the perspective section this check takes minutes and
   shows the tightening is real (over 99 % of the root gap closed), for +14 % columns
   *(field measurement)*. That justified the full benchmark. Remember that equal root
   bounds do not predict equal performance.
3. **Read what the solver receives.** Export the solver's model (`writeprob`, with
   `auxfiles rc` for names; see `../mp-library/tools-troubleshooting-and-reformulation.md`)
   and check whether a logical construct arrived as linear rows, indicators or general
   constraints. Count the columns and rows each reformulation removes or adds. A
   restatement that removes neither probably re-expands to the same auxiliaries, and gains
   readability rather than speed.
4. **Find out which solvers can solve the reference formulation at all.** A solver that
   cannot solve the hand formulation gives no evidence about variants of it. Also check
   that each solver actually received the file you think it did.

For how to compare the measurements once you have them (paired instances, seeds,
cross-checking bounds), see `../benchmarking-and-validation.md`.

## Worked examples

Runnable notebooks on the AMPL Model Colaboratory, by tag:
https://colab.ampl.com/tags/big-m.html (declared bounds and big-M, reading the exported
model), https://colab.ampl.com/tags/perspective.html (perspective reformulation, root-bound
check), https://colab.ampl.com/tags/formulation-comparison.html. The MP modeling guide
covers the same ground: https://mp.ampl.com/modeling-formulations.html.

## References

- Balas, E. (1985). Disjunctive programming and a hierarchy of relaxations for discrete
  optimization problems. *SIAM J. Algebraic Discrete Methods* 6(3), 466–486.
- Bonami, P., Lodi, A., Tramontani, A., Wiese, S. (2015). On mathematical programming
  with indicator constraints. *Math. Programming* 151(1), 191–223.
- Coffrin, C., Hijazi, H., Van Hentenryck, P. (2015). Strengthening convex relaxations
  with bound tightening for power network optimization. *CP 2015*, LNCS 9255.
- Conforti, M., Cornuéjols, G., Zambelli, G. (2014). *Integer Programming*. Springer.
- Frangioni, A., Gentile, C. (2006). Perspective cuts for a class of convex 0–1 mixed
  integer programs. *Math. Programming* 106(2), 225–236.
- Glover, F. (1975). Improved linear integer programming formulations of nonlinear
  integer problems. *Management Science* 22(4), 455–460.
- Grossmann, I.E., Trespalacios, F. (2013). Systematic modeling of discrete-continuous
  optimization models through generalized disjunctive programming. *AIChE J.* 59(9).
- Günlük, O., Linderoth, J. (2010). Perspective reformulations of mixed integer nonlinear
  programs with indicator variables. *Math. Programming* 124, 183–205.
- Liberti, L. (2009). Reformulations in mathematical programming: definitions and
  systematics. *RAIRO-RO* 43(1), 55–85.
- Pritsker, A.A.B., Watters, L.J., Wolfe, P.M. (1969). Multiproject scheduling with
  limited resources: a zero-one programming approach. *Management Science* 16(1), 93–108.
- Raghunathan, A.U. (2013). Global optimization of nonlinear network design. *SIAM J.
  Optim.* 23(1), 268–295.
- Rajan, D., Takriti, S. (2005). Minimum up/down polytopes of the unit commitment problem
  with start-up costs. IBM Research Report RC23628.
- Sousa, J.P., Wolsey, L.A. (1992). A time indexed formulation of non-preemptive single
  machine scheduling problems. *Math. Programming* 54, 353–367.
- Vielma, J.P. (2015). Mixed integer linear programming formulation techniques. *SIAM
  Review* 57(1), 3–57.

## See also

- `integer-programming.md` — the basic binary-variable idioms this file builds on
- `../mp-library/expressions-and-modeling-guide.md` — the logical operators themselves
- `../mp-library/efficiency-and-numerical-accuracy.md` — MP's own efficiency and
  big-M/bound guidance
- `../mp-library/tools-troubleshooting-and-reformulation.md` — exporting the solver's
  model, the Reformulation Explorer
- `nlp-formulation-choices.md` — the corresponding choices for nonlinear models
- `../benchmarking-and-validation.md` — how to compare formulations without fooling
  yourself
