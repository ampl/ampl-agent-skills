# MP Expressions and Modeling Guide

Derived from: mp-expressions-supported.md, mp-tools-and-details.md (native constructs by driver)

Source: `mp-expressions-supported.md` (`https://mp.ampl.com/modeling-expressions.html`).

MP-based solver interfaces work with existing AMPL syntax but accept it in more general
contexts and across a wider range of solvers than earlier ASL-based drivers did. Two kinds
of entities recur through the syntax summaries below:

- **expr** — any expression that evaluates to a number; may contain variables, and may be
  built from ordinary arithmetic as well as the operators covered here.
- **constr** — a constraint that evaluates to true or false; built from the familiar
  relational operators (`>(=)`, `<(=)`, `=`) as well as operators like `or` and `alldiff`
  that produce constraints directly.

Operators combine freely — an `expr`-valued or `constr`-valued result from one operator can
feed into another, letting AMPL build up arbitrarily complex expression trees:

```ampl
x<=0 or (y!=2  ==>
         x<=-5 else
               max((x+1)*x*z, y, y-z)<=3 and exp(y)<=12);
```

AMPL represents such combinations as expression trees and hands them to the MP-based
interface, which processes them however the target solver requires.

Indexing follows AMPL's usual `{ indexing } expr` form (AMPL book §5.5 and Chapter 6), or
a parenthesized, comma-separated `( expr-list )`, whose entries may themselves be `expr`,
`{indexing} expr`, or a nested `{indexing} ( expr-list )`. `max` accepts both forms:

```ampl
max {n in NODE} weight[t,n] * Use[n]
max (cost["BRO"], cost["CAU"], cost["BRU"])
max ({f in FOOD} cost[f], 10.0)
```

**Non-closed feasible regions.** Because MP accepts general operators like strict
inequalities inside constraints, it's possible to write a model whose feasible region
isn't topologically closed (e.g. `x > 5` with `x` minimized has no minimum). Where
necessary, MP closes the region with a small tolerance (`x >= 5 + eps`); the tolerance is
controlled by option `cvt:mip:eps`. Reformulations MP itself performs are configured
through MP options (`acc:...`, `cvt:...` — see `tools-troubleshooting-and-reformulation.md`);
reformulations AMPL performs before handing off to the solver are configured through AMPL
options.

## Conditional operators

- `if constr then expr1 [else expr2]` — *expr-valued.* Takes `expr1` when `constr` is
  true, `expr2` (or 0) when false. If `constr` contains no variables, AMPL can resolve the
  value before solving; otherwise the whole expression goes to the solver.
- `constr1 ==> constr2 [else constr3]` — *constr-valued.* Satisfied when `constr1` is true
  and `constr2` is true, or when `constr1` is false (and `constr3` holds, if present).
- `constr2 <== constr1` — the reverse-arrow form of the same implication.
- `constr1 <==> constr2` — *constr-valued.* Satisfied when `constr1` and `constr2` agree
  (both true or both false).

```ampl
subject to Balance {p in PROD, t in TIME}:
   Make[p,t] + (if t = 0 then inv0[p] else Inv[p,t-1])
      = Sell[p,t] + Inv[p,t];

subject to Least_Use {j in SCHEDS}:
   Use[j] = 1 ==> Work[j] >= least_assign else Work[j] = 0;
```

Read `constr1 ==> constr2` as "`constr1` implies `constr2`." When `constr1` has the form
*binary-var* = 0 or *binary-var* = 1, this is an "indicator" constraint some solvers
handle natively; otherwise it's transformed into relational-operator constraints.

AMPL transmits `b = 1 ==> constr2` as the disjunction `b != 1 or constr2`; MP recovers
the indicator form. A disjunction *literal* `or` *constr2*, where *constr2* is a
comparison (or a conjunction of comparisons) not used elsewhere, becomes indicator(s) on
the binary — saving an auxiliary binary and a constraint per implication, with the same LP
relaxation (option `cvt:pre:disj2ind`). This also applies under MP2NL with full
linearization (e.g. `config=knitro`).

For a variable declared `var x in {0} union interval[L, U]`, AMPL adds a binary `b` with
`x >= L*b` and `x <= U*b`. A comparison of `x` with a threshold in `[0, L]` (e.g.
`x >= L/2`, `x = 0`) is then decided by `b`, and MP reuses `b` instead of creating a new
binary (option `cvt:pre:vbnd`); likewise for a disjunction such as `x = 0 or x >= L`.
`../modeling-patterns/choosing-formulations.md` uses this for the perspective
reformulation.

## Logical operators

- `constr1 or constr2`, `constr1 and constr2`, `not constr` — the usual Boolean
  connectives, *constr*-valued.
- `exists {indexing} constr`, `forall {indexing} constr` — the iterated forms of `or` and
  `and`: satisfied when at least one / all of the indexed `constr` operands hold.

Solvers with native AND/OR constraints (Gurobi, Xpress, SCIP, CP-SAT) receive them
directly; for other solvers they are transformed into simpler relational-operator
constraints. Whether a solver accepts a construct natively is shown by its acceptance
option (`<solver> -=acc:`) and in the driver table in
`tools-troubleshooting-and-reformulation.md`.

```ampl
subj to No_Conflict {i1 in JOBS, i2 in JOBS: ord(i1) < ord(i2)}:
   Start[i2] >= Start[i1] + t_offset[i1,i2]  or
   Start[i1] >= Start[i2] + t_offset[i2,i1];

subj to HostNever {j in BOATS}:
   isH[j] = 1 ==> forall {t in TIMES} H[j,t] = j;
```

## Piecewise-linear expressions

- `abs(expr)` — `expr` if ≥ 0, else `-expr`.
- `min {indexing} expr` / `min (expr-list)`, `max {indexing} expr` / `max (expr-list)` —
  smallest/largest value among the operands.
- `<< breakpoint-list; slope-list >> var` — a piecewise-linear function of a single
  variable; full notation covered in AMPL book Chapter 17.

Solvers with native support receive `abs`, `min` and `max` directly (`abs`: Gurobi,
Xpress, COPT, SCIP, CP-SAT; `min`/`max`: Gurobi, Xpress, CP-SAT). Otherwise they become
relational-operator constraints, linearized when every operand is linear:

```ampl
minimize Max_Cost:
   max {i in PEOPLE} sum {j in PROJECTS} cost[i,j] * Assign[i,j];
```

For the general `<<breakpoints;slopes>>` form, **set AMPL option `pl_linearize` to 0 for
MP solvers.** With `pl_linearize=0`, the piecewise-linear expression reaches the solver
interface as an expression tree, and MP transforms it to the solver's native
piecewise-linear handling (Gurobi, CPLEX, Xpress) or linearizes it for other solvers
(for example COPT, HiGHS, MOSEK). At AMPL's default `pl_linearize=1`, AMPL itself linearizes the function
before the solver interface ever sees it — continuously in convex/concave cases, with
added binary variables otherwise. When a piecewise-linear function ends up linearized
(either path), bound the argument and result variables tightly (at most `[-1e4, 1e4]` is
recommended) for numerical stability — see `efficiency-and-numerical-accuracy.md`.
A convex piecewise-linear cost charged only while a unit is on (a semicontinuous variable)
has a stronger linear formulation, the perspective
(`../modeling-patterns/choosing-formulations.md`).

```ampl
minimize Total_Cost:
   sum {i in ORIG, j in DEST}
      <<{p in 1..npiece[i,j]-1} limit[i,j,p];
        {p in 1..npiece[i,j]} rate[i,j,p]>> Trans[i,j];
```

**This section extends the treatment of piecewise-linear functions in
`../modeling-patterns/piecewise-linear-programs.md`** — the `<<...>>` notation and
detection rules described there are unchanged, but MP-based solvers add native solver
support as an alternative to AMPL's own LP/MIP linearization, gated by the
`pl_linearize=0` recommendation above.

## Counting operators

- `count {indexing} constr` — *expr-valued:* number of indexing-set members for which
  `constr` holds.
- `atleast k {indexing} constr`, `atmost k {indexing} constr`, `exactly k {indexing}
  constr` — *constr-valued* shorthands for common `count` comparisons (`k` must be a
  nonnegative-integer-valued constant expression).
- `numberof expr in (expr-list)` — *expr-valued:* how many entries of `expr-list` equal
  `expr`.

Constraint programming solvers (CP-SAT) receive `count` and `numberof` natively; other
solvers get MP's reformulation.

```ampl
subject to Min_Serve {i in ORIG}:
    atleast minserve {j in DEST} (Ship[i,j] >= minload);

subj to CapacityOfMachine {k in MACHINES}:
    numberof k in ({j in JOBS} MachineForJob[j]) <= cap[k];
```

## Relational and comparison operators, and `alldiff`

- `expr1 > expr2`, `>=`, `<`, `<=`, `==`/`=`, `!=` — the ordinary relational operators,
  *constr*-valued. Where possible (e.g. integer-valued operands, or an `if ... > 0 then
  ...` fixed-cost pattern) strict operators transform into `>=`/`<=`; otherwise a small
  tolerance is introduced, as with the non-closed-region case above. Numerical accuracy
  implications are covered in `efficiency-and-numerical-accuracy.md`.
- `alldiff {indexing} expr` / `alldiff (expr-list)` — *constr*-valued: every operand takes
  a distinct value. A concise alternative to writing `!=` between every pair. CP-SAT
  receives it natively; for other solvers MP reformulates it (for a small domain, the
  assignment formulation can be stronger — `../modeling-patterns/choosing-formulations.md`).
- `!=` on a variable that is continuous to the solver (even one declared in a finite set)
  is at the mercy of feasibility tolerances; see "Counting changes of a continuous
  variable" in `efficiency-and-numerical-accuracy.md`.

```ampl
subject to Different_Colors {(c1,c2) in Neighbors}:
   Color[c1] != Color[c2];

subject to OnePersonPerPosition:
   alldiff {i in 1..nPeople} Pos[i];
```

## Complementarity operator

- `constr1 complements constr2` — satisfied when both hold and at least one holds with
  equality; each side must be a single inequality (or the trivial equality case).
- `expr complements constr` / `constr complements expr` — satisfied when `constr` (a
  double inequality `lb <= expr2 <= ub`) holds, and `expr`'s sign pins which bound is
  active: positive `expr` forces the lower bound to equality, negative forces the upper
  bound.

```ampl
subject to Pri_Compl {i in PROD}:
   Price[i] >= 0 complements
      sum {j in ACT} io[i,j] * Level[j] >= demzero[i] - demrate[i] * Price[i];
```

`complements` expresses complementary-slackness/equilibrium relationships directly —
see the full worked derivation, satisfaction rules, and suffix mechanics (`.Lsuf`/`.Rsuf`)
in `../modeling-patterns/complementarity-problems.md`; the AMPL book's Chapter 19 covers
it in full. Knitro handles complementarity constraints natively; for other MP-based
solvers the interface converts `complements` into logical or nonlinear-function
equivalents, controlled by options `cvt:compl` and `cvt:compl:tol` (alias
`cvt:compl:eps`); the four reformulations are tabulated in the MP2NL section of
`tools-troubleshooting-and-reformulation.md`.

## Set membership operator

- `var var-name in set-expr;` — restricts a variable's domain to the (numeric) members of
  `set-expr`. Valid in any `var` definition without an `=` phrase.

**Work in progress (MP library):** this feature is currently under rework upstream. Until
further notice, prefer disjunctive constraints (`||`) over `in set-expr`/`interval[...]`
domain restrictions, especially when the variable also participates in logical expressions:

```ampl
# avoid:
var grade in 0..2 union {5} union interval[8.1,9] union interval[10,13.7];

# prefer:
var grade >= 0 <= 13.7;
s.t. GradeDomain:
    grade <= 0 || grade == 1 || grade == 2 || grade == 5
        || 8.1 <= grade <= 9 || grade >= 10;
```

Which of the two forms solves faster depends on the model and the solver: on two models of
the same structure they won in opposite directions. Where performance matters, try both
(`../modeling-patterns/choosing-formulations.md`).

AMPL rewrites `in set-expr` to an equivalent definition without `in` before the solver ever
sees it — typically introducing auxiliary binary variables and constraints. For a finite
`set-expr`, AMPL also defines suffixes `.sos`/`.sosref`, letting the solver interface
recognize the construct and, where the solver supports it, implement it as a
special-ordered-set-of-type-1 (SOS1) rather than binaries. `set-expr` may also include
continuous intervals via `interval[expr1,expr2]`, making the domain infinite:

```ampl
var Buy {f in FOODS} in {0,10,30,45,55};
var Ship {(i,j) in ARCS} in {0} union interval[min_ship,capacity[i,j]];
```

## Quadratic and power operators

- `expr1 * expr2`, `expr1 / expr2` — multiplication, division.
- `expr1 ^ expr2` — power. For constant positive-integer `expr2`, the operator goes to
  the solver natively if supported, else decomposes into quadratic constraints if the
  solver supports those, else falls back to piecewise-linear approximation (see "General
  nonlinear functions" below).

For `linear * linear` and `linear^2` forms, MP multiplies out the product so individual
quadratic-term coefficients can be extracted and passed to a solver with native quadratic
support. Otherwise:

- a product with a **binary** variable is linearized exactly;
- a product with an **integer variable of finite bounds** (the other factor bounded too)
  is reformulated exactly by binary expansion of the integer factor with the smaller range,
  `y = l_y + sum_j 2^j b_j` (Gupte, Ahmed, Cheon & Dey 2013). Option
  `cvt:mip:intprodbits` limits the number of binaries (default 30; 0 restores the
  approximation); integer powers `x^k` are built from such products;
- other products `x*y` are approximated as `((x+y)^2 - x^2 - y^2)/2` with
  piecewise-linear squares.

Equal products share their reformulation. CP-SAT receives products and integer powers
natively (`acc:mul`, `acc:powc`). For linear solvers this multiply-out/linearize path is the default; for
**convex MIQP solvers**, force linearization instead of native quadratic handling with
`cvt:quadobj=0` / `cvt:quadcon=0`. Piecewise linearization of quadratics also lets convex
MIP solvers handle nonconvex QP/nonlinear models they couldn't otherwise accept.

Other combinations reduce to auxiliary variables plus quadratic expressions/equalities:

```
(x-1)^3  ⇒  (x-1) * y  with added constraint  y = (x-1)^2
x * max {j in 1..n} y[j]  ⇒  x * z  with added constraint  z = max {j in 1..n} y[j]
```

## Rounding and integer division

- `floor(expr)`, `ceil(expr)`; `round(expr [, n])`, `trunc(expr [, n])` — rounding to an
  integer, or to `n` decimal places (`n` a constant integer). `round` rounds ties to even,
  as AMPL does (`round(2.5) = 2`).
- `expr1 div expr2`, `expr1 mod expr2` — truncated quotient `trunc(expr1/expr2)` and
  remainder `expr1 - expr2*(expr1 div expr2)`, which has the sign of `expr1`; also for
  real numbers (`7.5 mod 2 = 1.5`).

For an integer argument, `floor`/`ceil`/`round`/`trunc` return the argument itself.
Otherwise MP introduces an integer variable `r` with tolerance `eps` (option
`cvt:mip:eps`):

- `r = floor(x)`: `r <= x <= r + 1 - eps` (`ceil` symmetrically);
- `r = round(x)`: `r = 2m + p` with integer `m` and binary `p`, `|x - r| <= 1/2 - eps*p`, so
  a tie rounds to the even neighbor;
- `trunc` uses `floor` for nonnegative and `ceil` for nonpositive arguments;
- `q = x div y`: with remainder `rho = x - y*q`, `|rho| <= |y| - eps` (1 for integer
  `rho`), `rho` has the sign of `x`, and `y != 0`. For a variable divisor `y*q` is a
  product, reformulated exactly for bounded integer `q`; `mod` reuses the quotient.

Decimal values such as 0.15 are not exact in binary floating point, so ties of
`round(x, n)` with `n > 0` can be resolved differently from AMPL's own evaluation; AMPL's
`trunc(x, n)` with negative `n` can differ from the mathematical truncation MP applies.
CP-SAT receives `div` and `mod` natively (`acc:intdiv`, `acc:mod`).

## Conic optimization

Mosek, Gurobi, COPT, SCIP, CPLEX, and Xpress can handle conic constraints with tailored
algorithms (general nonlinear solvers accept the same syntax but without a specialized
conic algorithm). Worked examples: AMPL Colab (`https://colab.ampl.com/tags/conic.html`).

**Second-order cone programming (SOCP).** SOCP constraints (quadratic cones) are
recognized from their algebraic form by major commercial MIP solvers; MP provides
additional conversion into solver-specific conic forms for some representations.

```ampl
# Standard SOC (x[0] >= 0):
x[0] >= sqrt(x[1]^2 + ... + x[n]^2);

# Rotated SOC (x[0], x[1] >= 0):
2*x[0]*x[1] >= x[2]^2 + ... + x[n]^2;
```

Mosek cannot mix SOCP and general quadratic constraints in the same model (errors with
`MSK_RES_ERR_MIXED_CONIC_AND_NL`) — use a standard SOCP form throughout, or tune options
`cvt:socp`/`cvt:socp2qp`.

**Redundant convex constraints on lifted variables.** MP recognizes a cone from its
algebraic form, so the cone's variables must appear by name — inline them and the
structure is gone. When the model's own definitions imply a convex inequality, adding it
can give a global solver the convex bound it lacks (the AC power-flow lift
`Wc^2 + Ws^2 <= Wii[i]*Wii[j]`, Jabr 2006). Full treatment, with the example and its
limits: `../modeling-patterns/nlp-formulation-choices.md`.

**Exponential cones.** MOSEK and COPT natively handle these; MP recognizes and passes them
via the solver's API:

```ampl
s.t. T1: 1 + b*w >= exp( q1 );
s.t. T2: -1 + w +10*q2   <= -5 * q2 * exp( q1 / (q2*5) );
```

Mosek also cannot mix conic and general quadratic constraints — use `cvt:expcones=0` to
force an alternative handling (piecewise-linear approximation, for Mosek) if needed.

To see which constraints actually reached the solver as conic vs. quadratic, export the
solver's model — see "Export the solver model" in
`tools-troubleshooting-and-reformulation.md`.

## General nonlinear functions

**Supported functions:** `log`, `log10`, `exp`; `sin`, `cos`, `tan`, `asin`, `acos`,
`atan`; `sinh`, `cosh`, `tanh`, `asinh`, `acosh`, `atanh`; and `^` (power), whose handling
depends on which operand is a constant: for two variable operands it goes natively if
supported, else reformulates as `exp(expr2 * log(expr1))`; for constant positive base,
native or piecewise-linear approximation; for constant positive-integer exponent, native,
quadratic decomposition, or piecewise-linear approximation, in that preference order.
Disable native handling with `acc:pow=0`, `acc:expa=0`, or `acc:powconstexp=0` respectively.

**Recognized from the model** (for solvers that accept them natively — Gurobi; other
solvers receive the original expression):

- `signpow(x, p) := sign(x) |x|^p` (p > 1) — recognized from forms like
  `abs(x+x*y+7)^0.5*(x+x*y+7)` (→ `signpow(x+x*y+7, 1.5)`) or `sqrt(z^2)^2.3*z` (→
  `signpow(z, 3.3)`, single-variable argument only). Disable with `cvt:pre:signpow=0`.
  Prefer `sqrt` over `abs` for this pattern — `abs` is only eliminated (and the pattern
  recognized) when its argument's deduced bounds have a definite sign; `sqrt` always
  converts, though it's less efficient for solvers without native `signpow`.
- `logistic(x) := 1 / (1 + e^(-x))` — recognized from forms like
  `0.9 / (1.0 + exp(-2*x - 1.5*y))` (→ `0.9*logistic(2*x + 1.5*y)`). Disable with
  `cvt:pre:logistic=0`.

**Piecewise-linear approximation.** For linear-quadratic MP-based solvers, most of these
nonlinear functions (except products with binary variables) are handled by
piecewise-linear approximation, controlled by `cvt:plapprox:reltol` and
`cvt:plapprox:domain`. Tight variable bounds reduce approximation size and improve
numerical behavior — same recommendation as for the `<<...>>` operator above.

**Handling by solver class:**

| Solvers | Handling |
|---|---|
| Gurobi, Xpress, SCIP; COPT with `acc:_expr=1` | Passed natively as expression trees. Gurobi and SCIP solve globally, Xpress too if its license allows (otherwise, or with `alg:nlpsolver=1`, locally); COPT solves locally |
| Linear-quadratic solvers (CPLEX, HiGHS, MOSEK, CBC, GCG, cuOpt; COPT by default) | Approximated piecewise-linearly, so the solver optimizes the approximation |
| NL solvers through MP2NL (e.g. Knitro, Ipopt, BARON) | Passed in the NL file, after MP's reformulation of the other constructs (`tools-troubleshooting-and-reformulation.md`) |

Which applies to a given solver is shown by its `acc:` options (`<solver> -=`). Gurobi's
own function-constraint options (`pre:funcpieces*`) are deprecated by Gurobi together with
function constraints (`../solver-options/gurobi-options.md`).

Example with many local minima, the Chichinadze test function:

```ampl
param pi := 4*atan(1);
var x {1..2} >= -30, <= 30;
minimize Chichinadze:
   x[1]^2 - 12*x[1] + 11 + 10*cos(pi*x[1]/2) +
      8*sin(pi*5*x[1]) - exp(-(x[2]-.5)^2/2)/sqrt(5);
```

```python
ampl.solve(solver="scip")            # or gurobi, xpress: global solvers
print(ampl.obj["Chichinadze"].value(), ampl.var["x"].to_list())
```

Gurobi, Xpress and SCIP all prove the global minimum −43.3159 at x ≈ (5.9013, 0.5); a
local solver can stop at a local minimum, and a linear-quadratic solver works with the
approximation, whose accuracy depends on the bounds and on `cvt:plapprox:reltol`.

**This section updates `../modeling-patterns/nonlinear-programs.md`** for anything
solver-interface-related — the modeling-patterns file's NLP pitfalls (local optima,
starting-point sensitivity) still apply, but MP's native/piecewise-linear-approximation
handling of these functions, and the `signpow`/`logistic` recognition above, are MP-layer
behavior not covered there.

## See also

- `overview-and-when-to-use.md` — what MP is and which solvers use it
- Piecewise-linear notation, detection rules, and non-`<<...>>`-expressible cases:
  `../modeling-patterns/piecewise-linear-programs.md`
- Complementarity: full derivation, satisfaction rules, suffixes:
  `../modeling-patterns/complementarity-problems.md`
- NLP-specific pitfalls (multiple local optima, starting points):
  `../modeling-patterns/nonlinear-programs.md`
- Bounding subexpressions and variables for solver performance and numerical stability:
  `efficiency-and-numerical-accuracy.md`
- `acc:` acceptance options controlling native vs. reformulated handling per constraint
  type, and exporting the solver's model to see what reformulation actually happened:
  `tools-troubleshooting-and-reformulation.md`
