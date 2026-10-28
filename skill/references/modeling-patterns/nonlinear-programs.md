# Nonlinear Programs: Sources, Variables, Expressions, Pitfalls

Derived from: ampl-book.md (ch. 18)

Source: *AMPL: A Modeling Language for Mathematical Programming*, 2nd ed., Chapter 18.

## Table of contents

- What counts as "nonlinear" here (smooth, continuous variables — not integer, not
  piecewise-linear)
- Where nonlinearity comes from: relaxed assumptions, engineered effects, physical laws
- Nonlinear variables: initial values, automatic substitution (`substout`, `= expr`)
- Writing smooth expressions; where `abs`/`if`/`min`/`max` silently break smoothness
- Pitfalls: function range violations, multiple local optima, scaling, other failure modes

## Scope: "nonlinear program" is a narrower term than "not linear"

In this book's usage, a nonlinear program (NLP) has **continuous** variables (not
integer/binary — that's Chapter 20) and a **smooth** objective/constraints: continuous,
with a well-defined gradient everywhere. Piecewise-linear terms (Chapter 17, this folder's
`piecewise-linear-programs.md`) and fixed-cost/discontinuous terms are "not linear" too,
but are handled by entirely different mechanisms (`<<...>>` translation, integer
variables) — don't reach for general nonlinear modeling techniques for those cases; use
the dedicated tool. AMPL can also express pure nonlinear equation/inequality *systems*
with no objective at all — some solvers specialize in exactly that (see the pipe-network
example at the end of the source chapter's exercises).

## Where nonlinearity comes from

Three recognizable sources, useful for diagnosing "why does this model need to be
nonlinear" and for choosing a good functional form:

**1. Dropping a linearity assumption.** A linear cost (`cost[i,j] * Ship[i,j]`) assumes a
constant per-unit rate. Replacing the constant with a variable-dependent expression —
e.g. a rate that declines as volume increases (concave, like volume discounts) or rises
steeply as a capacity limit is approached (convex) — captures more realistic economics at
the price of linearity:

```ampl
(cost1[i,j] + cost2[i,j]*Ship[i,j]) / (1 + Ship[i,j]) * Ship[i,j]
```

This levels off from `cost1` to `cost2` per unit as shipment volume grows — a concave
shape. The general technique: turn the constant rate into a variable, and add an equation
relating the new variable to the flow/decision variable it depends on
(`Cost[i,j] = (cost1[i,j] + cost2[i,j]*Ship[i,j]) / (1 + Ship[i,j]);`) — this is itself a
nonlinear constraint (division by an expression containing a variable), which is fine and
common.

**2. Engineering a specific effect no linear function can produce.** Example: travel time
that's roughly constant for light traffic but blows up as capacity is approached —

```ampl
time[i,j] + (sens[i,j]*Ship[i,j]) / (1 - Ship[i,j]/cap[i,j])
```

— convex, approaches infinity as `Ship[i,j] -> cap[i,j]`. Or a discrepancy/slack variable
penalized *quadratically* rather than piecewise-linearly, when you specifically want the
marginal penalty to keep growing without bound as the deviation grows (piecewise-linear
penalties, even with many pieces, always have a *finite* worst-case slope; `x^2` doesn't):
`pen * Discrepancy[k]^2`. Sum-of-squares objectives of this shape are the standard form
for data-fitting/approximation problems.

**3. Modeling an inherently nonlinear physical law.** Gas pipeline pressure-flow
relationships, electrical transmission, structural mechanics — the nonlinearity comes
from physics, not from a modeling choice, e.g.
`Flow[i,j]^2 = c[i,j]^2 * (Press[i]^2 - Press[j]^2)`. These tend to have more complex,
less "shapeable" functional forms than the economics-driven cases above, since the
formula is dictated by the underlying science rather than chosen for convenient
properties (convexity, boundedness).

## Nonlinear variables

### Initial values matter far more here than in LP

Every AMPL variable has a current value — used as the solver's starting guess at
`solve` time, then overwritten by the optimal value once solved. For linear programs the
starting guess barely matters (the algorithm ultimately finds a global optimum
regardless); for nonlinear programs it can determine *whether* the solver succeeds at
all, and *which* local optimum (if several exist) it reports — see "Multiple local
optima" below. Set initial values via `:=` in the declaration or a data statement, exactly
like a parameter default:

```ampl
var Ship {LINKS} >= 0, := 1;                          # uniform initial guess
var Ship {(i,j) in LINKS} >= 0, := cap[i,j] - 1;       # data-driven initial guess
```

Uninitialized variables default to 0 — an arbitrary starting point with no special status;
some of this chapter's own examples fail to solve at all from a zero start (see "Function
range violations" below) and need a nonzero initial guess instead. The same `:=`
mechanism initializes dual variable guesses via constraint names (a few solvers, like
MINOS, use these).

### Automatic substitution of "defined" variables

A variable declared via `Cost[i,j] = expr;` (an `=` phrase with no other restrictions —
no bounds, no integrality) is mathematically redundant: it could always be replaced by
`expr` everywhere it's used. AMPL can perform this substitution automatically before
handing the problem to the solver, two ways:

```ampl
option substout 1;                 # global: AMPL scans for "defining" constraints (single var = expr)
                                    #   and substitutes as many out as it safely can, in declaration order
var Cost {(i,j) in LINKS} = (cost1[i,j] + cost2[i,j]*Ship[i,j]) / (1 + Ship[i,j]);   # explicit, per-variable
```

Why bother, if the variable is mathematically removable anyway: naming a complex
sub-expression makes the model far more readable, and if the same nonlinear expression
recurs in several places, AMPL stores just one internal copy of its nonlinear part
(splitting linear and nonlinear parts, `option linelim` controls this) — cheap to write,
cheap to evaluate, and the variable's name and value remain available afterward for
`display` even though it never reaches the solver. Trade-off: substituting out variables
means fewer variables/constraints but more complex expressions per constraint — solver
performance can go either way, so treat it as something to experiment with rather than a
default "always better" choice on a new nonlinear model. (`nlp-formulation-choices.md`
gives a decision list and a switch pattern for keeping both forms testable.)

## Writing smooth expressions: where `abs`/`if`/`min`/`max` silently misbehave

AMPL will happily let you write `cost[i,j] * abs(Flow[i,j])` or an `if`-condition on a
variable inside an expression — and a solver may even report an "optimal" answer — but
these are **not smooth** (`abs` has a slope discontinuity at zero; `if`-on-a-variable can
even be *discontinuous*), and a smooth-function solver's results on them should not be
trusted. This is a genuinely dangerous silent-failure mode: nothing errors, the number
just may be wrong.

**Exception — some `if`/piecewise constructions ARE smooth**, when the pieces happen to
meet with matching value *and* slope at the junction. Two examples worth recognizing as a
pattern:

```ampl
# Two quadratic halves that meet smoothly at Flow[i,j] = 0 (both value and slope match there)
(if Flow[i,j] >= 0 then Flow[i,j]^2 else -Flow[i,j]^2) = c[i,j]^2 * (Press[i]^2 - Press[j]^2)

# Avoiding a 0/0 singularity with a numerically-close linear approximation near it
if abs(Flow[i,j]-1) > 0.00001 then log(Flow[i,j])/(Flow[i,j]-1) else 1.5 - Flow[i,j]/2
```

The second isn't literally, mathematically smooth, but is numerically close enough that
many solvers handle it fine — a pragmatic, not purist, use of `if`. When in doubt about
whether an `if`/`abs`/`min`/`max`-based expression is safe, check both value *and*
first-derivative continuity at the transition point by hand before trusting solver output
on it.

**Presolve interaction**: AMPL splits every objective/constraint into linear + nonlinear
parts and only presolves the linear part; fixing enough variables can turn a term that was
nonlinear (e.g. `Cost[i,j] * Ship[i,j]`) into a linear one once one of the factors is
fixed — recognized automatically, and relevant when using `fix` on a nonlinear model to
explore sub-problems.

**Importing functions not built into AMPL** (e.g. cumulative-normal from a stats library):
`load statlib.dll; function cumnormal; function invcumnormal;` — declare before use; full
mechanics of `function`/`load`/domain-checking in `12-syntax-quick-reference.md`
(section A.22).

## Pitfalls of nonlinear programming

Unlike LP, no nonlinear solver can be relied on to succeed on "almost any" well-posed
model — expect to debug.

### Function range violations

A convex cost like `rate*Trans/(1 - Trans/limit)` looks well-behaved on a truncated
graph but has a genuine singularity (division by zero, or worse, sign flip to `-Infinity`
just past it) exactly at `Trans = limit`. A solver is not guaranteed to keep the variable
strictly inside the "intended" range just because the objective heads toward `+Infinity`
there — nothing structurally prevents it from stepping slightly past the singularity into
the `-Infinity` region during its search, especially from an uninformative starting guess.
Symptoms include a division-by-zero evaluation error, or a solver reporting "optimal" (or
"cannot be improved") at a wildly, implausibly negative objective value.

**The fix is always an explicit bound that keeps the variable safely inside the function's
well-behaved domain**, not just relying on the objective's shape to imply one:

```ampl
var Trans {i in ORIG, j in DEST} >= 0, <= .9999 * limit[i,j];    # instead of unbounded above
```

A related case: a function whose *value* is fine at a boundary point (e.g. `x^0.8` at
`x=0`) but whose *derivative* is undefined or infinite there (`pow'(0, 0.8)`) will cause a
solver requiring derivatives to fail outright with a message like
`can't evaluate pow'(0,0.8)`. Fix by moving the bound strictly away from the problem
point: `var Trans {...} >= 1e-10, <= .9999*limit[i,j], := 0;` — note the initial value can
still safely be exactly at the boundary (`:= 0`) even though the *bound* must be strictly
inside it, since most solvers adjust an infeasible-derivative starting point automatically.

General lesson: when a nonlinear solve fails with a cryptic evaluation error, or succeeds
with an implausible objective value, suspect a variable sitting at or past a genuine
singularity/domain-boundary of one of your nonlinear expressions — `display` the
suspicious variable(s) at full precision (`option display_precision 0;` for full
precision) to check exactly how close to the boundary they landed.

### Multiple local optima

Classical NLP solvers find a **local** optimum — a point no better than any nearby
feasible point — with no general guarantee of global optimality, unless the problem has
special structure (convex objective + linear constraints, of which linear programming
itself is a further special case — this is *why* LP never has this problem). Two runs of
the identical model from two different starting guesses (`let {...} Trans[i,j] :=
limit[i,j]/2;` vs. some other value) can converge to **different, both "locally optimal,"
objective values** — in the source example, one 17% better than the other, purely as a
function of starting point.

Practical responses, roughly in order of effort:
- If you can argue the model is convex-objective/linear-constraints (or otherwise has a
  property guaranteeing local = global), a single solve is trustworthy.
- Otherwise, try a **systematic scan of starting points** (e.g. a parameterized initial
  guess `:= alpha * limit[i,j]` swept over `alpha in 0..1`) and keep the best result —
  cheap, and gives you at least an empirical sense of solution quality/stability even
  without a formal global guarantee.
- Use domain knowledge to pick a starting guess near the suspected global optimum, or add
  constraints that explicitly rule out known-bad regions.
- For a genuinely hard global-optimization need, note this reduces to a combinatorial
  problem in spirit, related to (and sometimes solved via techniques borrowed from)
  integer programming (`integer-programming.md`) — a specialized global solver, not a
  generic local NLP solver, is the right tool.

### Other common failure modes and mitigations

- **Nonlinearities in constraints are harder to handle than in the objective** — where you
  have a choice of formulation, prefer pushing nonlinearity into the objective.
- **Variable scaling**: keep variable magnitudes within a few orders of magnitude of each
  other; solvers can be misled when some variables are in the millions and others in the
  thousandths. Picking natural units carefully is cheap insurance; some solvers
  auto-scale, but don't rely on it.
- Solvers can also get stuck at non-optimal stationary points, converge to a maximum when
  a minimum was wanted (or vice versa), or falsely report infeasibility. Mitigations:
  different starting guess (ideally feasible with respect to the nonlinear constraints),
  and realistic "safety" bounds on variables (tighter than the true bounds, just to keep
  the search in a sane region) — but always check afterward whether a safety bound was
  actually *reached* by the optimal solution; if so it was probably too tight and should
  be relaxed and re-solved.

## See also

- When to substitute (reduced space) and when to keep a named variable (full space),
  coordinate choice and problem class, redundant convex constraints on lifted
  quantities, starting points and smoothing, with measured trade-offs:
  `nlp-formulation-choices.md`
- Piecewise-linear alternatives when a nonlinear cost can be adequately approximated by a
  handful of linear segments (often easier to solve reliably): `piecewise-linear-programs.md`
- Network models whose flow/pressure relationships become genuinely nonlinear (gas,
  electrical): `network-models.md`
- `fix`, presolve, and how fixing variables can linearize part of a nonlinear model:
  `08-commands-modifying-models-and-data.md`, `11-solver-interaction-and-suffixes.md`
- Full `function`/`load`/pipe-function mechanics for imported nonlinear functions:
  `12-syntax-quick-reference.md` (section A.22)
