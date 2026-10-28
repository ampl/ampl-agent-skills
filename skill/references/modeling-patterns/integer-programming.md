# Integer and Mixed-Integer Programs: `integer`, `binary`, Logical Conditions

Derived from: ampl-book.md (ch. 20)

Source: *AMPL: A Modeling Language for Mathematical Programming*, 2nd ed., Chapter 20.

## Table of contents

- Declaring integer variables; when a solver silently ignores integrality
- When you can get away without integer variables at all
- Binary variables for logical conditions: fixed costs, zero-or-minimum, cardinality
- Practical advice: fewer integer variables, tighter bounds, tighter relaxations

## Declaring integer variables

```ampl
var Buy {j in FOOD} integer >= f_min[j], <= f_max[j];
var Use {ORIG,DEST} binary;                    # shorthand for integer, >= 0, <= 1
```

`integer` restricts a variable to whole numbers; `binary` is the 0/1 special case,
equivalent to `integer >= 0, <= 1` but clearer to read and write.

**Not every solver honors integrality** — some (the source example uses MINOS, a
continuous NLP/LP solver) simply ignore the restriction and print a warning
(`ignoring integrality of N variables`) rather than erroring, then return whatever
continuous-relaxation optimum they'd have found anyway. This is a genuinely easy mistake
to make silently: a model with `integer`/`binary` declarations solves without complaint,
looks plausible, and is simply *wrong* if the active solver doesn't support MIP. Always
confirm the solver in use actually handles integrality
(`option solver cplex;` or another MIP-capable solver) before trusting an integer result;
don't infer solver capability from the absence of an error.

Rounding a continuous-relaxation solution to the nearest integers is **not** a reliable
way to reach the integer optimum — the source diet example shows the true integer optimum
moving one variable *up* to 9 (from a fractional 5.36) while moving another *down* to 7
(from a fractional 9.31), a pattern rounding would not have predicted; small changes to
formulation or data can shift which variables need to move, and in which direction.

## When you might not need integer variables at all

Several situations produce integer-valued optimal solutions from an ordinary LP solve,
with no `integer` declaration needed:

- **Pure network LPs** with integer data are guaranteed integer-optimal (see
  `network-models.md`, §15.5) — this is the strongest and most reliable case.
- **Extreme-point LP solutions** in general have at most as many non-bound variables as
  there are constraints; if bounds and data are integral, many — sometimes all —
  variables land on integers anyway, "for free," purely as a side effect of how the
  simplex method behaves. Worth checking an LP relaxation's solution before assuming a
  full MIP formulation is necessary — you may already have (or nearly have) an integer
  answer, especially in models where variables greatly outnumber constraints (a wide,
  underdetermined LP, as in the scheduling example in `columnwise-formulations.md`).
- If most but not all variables come out integer, it may be practical to manually round
  just the few remaining fractional ones to a nearby feasible integer solution — a
  pragmatic middle ground between "declare everything integer" (expensive) and "ignore
  the issue" (wrong), viable specifically when few variables need adjustment and a
  slightly-suboptimal-but-feasible answer is acceptable.

Given how much more expensive MIP solving is (see "Practical considerations" below),
checking whether one of these situations applies before reaching for `integer` is worth
the effort on any model of meaningful size.

## Binary variables for logical conditions

Zero-one variables are the standard device for expressing conditions that cannot be
written as ordinary linear inequalities — "this route is either unused or costs an extra
fixed amount," "ship nothing or at least a minimum load," "serve at most N destinations."
**AMPL does not accept `or`, `if`-conditions-on-variables, or `card{}` of a
variable-dependent set inside constraints** — each of the direct, "obvious" ways of
writing these conditions is rejected or silently mishandled; the binary-variable
reformulations below are the standard workaround, not just one option among several.

### Fixed costs (activate-or-don't, with a fixed penalty)

```ampl
var Use {ORIG,DEST} binary;                     # 1 iff route i,j is used at all
minimize Total_Cost:
   sum {i in ORIG, j in DEST, p in PROD} vcost[i,j,p] * Trans[i,j,p]
 + sum {i in ORIG, j in DEST} fcost[i,j] * Use[i,j];
subject to Multi {i in ORIG, j in DEST}:
   sum {p in PROD} Trans[i,j,p] <= limit[i,j] * Use[i,j];    # <= 0 when Use=0, forces Trans to 0
```

The tempting direct approach —
`if sum{p in PROD} Trans[i,j,p] > 0 then fcost[i,j]` inside the objective — is accepted
syntactically but is nonsmooth/nonlinear in the sense of `nonlinear-programs.md` and
won't optimize reliably; this is the *linear*, MIP-compatible substitute. The trick:
multiplying the capacity bound by `Use[i,j]` forces `Trans` to zero when `Use=0`, and
(since `fcost[i,j]` is positive, so the optimizer never wants `Use=1` with zero shipment)
`Use[i,j]` is 1 exactly when the route is actually used — the "clever part" of the
formulation is entirely in that one multiplication.

### Zero-or-minimum (all-or-nothing thresholds)

```ampl
subject to Min_Ship {i in ORIG, j in DEST}:
   sum {p in PROD} Trans[i,j,p] >= minload * Use[i,j];
```

When `Use[i,j] = 1` this becomes the real minimum-load constraint; when `Use[i,j] = 0` it
reduces to `... >= 0`, which is automatically satisfied and imposes nothing — the
"either zero or at least `minload`" logic, expressed as one linear constraint reusing the
same activation variable as the fixed-cost pattern above.

### Cardinality restrictions (limit how many things are "on")

```ampl
subject to Max_Serve {i in ORIG}: sum {j in DEST} Use[i,j] <= maxserve;
```

`card {j in DEST: sum{p in PROD} Trans[i,j,p] > 0}` (cardinality of a set defined by a
variable-dependent condition) is rejected outright — AMPL does not allow constraints to
reference sets defined in terms of variables. Because `Use[i,j]` already indicates
"route i,j is active" as a 0/1 value, a plain sum of `Use` values over the relevant index
*is* the cardinality — no `card{}` needed once you already have the activation variable
from the fixed-cost pattern.

**The general idiom running through all three patterns**: introduce one binary
"indicator" variable per logical condition, then use multiplication (`bound * Use[...]`)
or summation (`sum {...} Use[...]`) to tie continuous decisions to that indicator — this
single idiom (indicator variable + linked constraint) covers most everyday integer-
programming logic without needing a distinct trick per situation.

## Practical considerations: integer programs are much harder

Solver iteration counts in the source examples jump from ~40 (pure LP) to 280-400+ (MIP
variants of the same model) — and difficulty grows *faster than problem size* for integer
programs, unlike LP. Before committing to an integer formulation on a model of real size:

- **Check whether a continuous or network formulation could give an adequate answer**
  (see "When you might not need integer variables" above) — the cheapest possible
  mitigation is not needing MIP at all.
- **Test on gradually larger data** to get an empirical sense of how solve time scales
  before committing to full-scale data.
- **Use as few integer variables as possible.** Every additional integer variable
  multiplies the combinatorial search space the solver must (implicitly) explore.
- **Tighten bounds on non-binary integer variables** as much as the problem genuinely
  allows — tighter bounds prune more of the branch-and-bound search tree.
- **Tighten the LP relaxation itself**, not just variable bounds. Solvers derive most of
  their pruning power from solving relaxations (integrality dropped) at each node; a
  relaxation whose optimal solution is *naturally* close to integral is easier to branch
  from than one that isn't, even when both relaxations are mathematically equivalent
  after adding integrality back in. Example — strengthening the `Trans`/`Use` link so the
  relaxation itself pushes `Use` toward 0/1 rather than leaving it free to sit at an
  unhelpful fractional value:
  ```ampl
  subject to Avail {i in ORIG, j in DEST, p in PROD}:
     Trans[i,j,p] <= min(supply[i,p], demand[j,p]) * Use[i,j];
  ```
  This adds no new *feasible integer* solutions and removes none — it only changes the
  shape of the relaxation's feasible region — but can measurably speed up the solve on
  large instances by giving the solver a more accurate picture to branch from. The
  trade-off (more constraints to carry) usually only pays off once a problem is
  substantially larger than a toy example; don't add this kind of strengthening
  preemptively on small models.
- **Solver-specific tuning options** (branching strategy, node limits, etc.) can matter
  significantly — consult the specific solver's documentation rather than assuming
  defaults are well-tuned for your problem's structure.
- **Accept a near-optimal stopping criterion** when available (most MIP solvers can stop
  once within a specified percentage of the best possible bound, aka a "MIP gap") — often
  finds a solution close to optimal far faster than proving true optimality, and is a
  legitimate practical trade-off rather than a compromise to be embarrassed about.
- Expect to **experiment**: formulation choices that barely matter for LP (constraint
  ordering, exact algebraic form of an equivalent constraint) can change MIP solve time
  by orders of magnitude, and predicting which reformulation will help ahead of time is
  often not possible without just trying it.

## See also

- Choosing between logical (MP) and hand formulations, declared bounds for big-M,
  indicators vs. big-M, and known formulations (time-indexed, perspective, convex hull),
  with measured trade-offs: `choosing-formulations.md`
- Why `if`/logical conditions on variables can't be used directly in linear constraints,
  and the nonsmoothness that results from trying: `nonlinear-programs.md`
- Piecewise-linear terms that themselves compile down to an integer-programming
  formulation in the non-convex/non-concave case: `piecewise-linear-programs.md`
- Set-covering/scheduling problems, where the LP relaxation is often already close to
  integral (columnwise formulation background): `columnwise-formulations.md`
- Network models whose integer-optimality is automatic and needs no `integer` declaration
  at all: `network-models.md` (section 15.5)
- Solver selection, `option solver ...;`, and the general solve/presolve pipeline:
  `11-solver-interaction-and-suffixes.md`
