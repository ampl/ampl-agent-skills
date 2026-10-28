# MP Library: Overview and When to Use It

Derived from: mp-library.md, mp-modeling-overview.md, mp-solver-drivers.md, mp-modeling-guide.md, mp-tools-and-details.md (native constructs by driver)

Source: `mp-library.md` (`https://mp.ampl.com/`), `mp-modeling-overview.md`
(`https://mp.ampl.com/modeling-overview.html`), `mp-solver-drivers.md`
(`https://mp.ampl.com/drivers.html`), `mp-modeling-guide.md`
(`https://mp.ampl.com/model-guide.html`).

## What MP is

MP is AMPL's newer C++ solver-interface library — the recommended foundation for building
new AMPL solver drivers, publicly available in the `ampl/mp` GitHub repository
(`https://github.com/ampl/mp`). It provides type-safe, flexible interfaces suitable for
linear, mixed-integer, non-linear, and constraint-programming solvers, and is implemented
in C++ with parts of the API exported in C. Alongside the driver framework itself, MP
bundles a set of supporting tools: an automatic solution checker (built into every
MP-based solver, no configuration needed to get baseline checking), a Model Reformulation
Explorer, the MP2NL meta-driver, and a lightweight NL writer.

MP replaces the previous AMPL Solver Library (ASL) for solvers that don't require
automatic differentiation. In practice this means: if a solver driver is built on MP, it
inherits a materially larger vocabulary of AMPL expressions it can accept and solve than
an ASL-based driver would.

## Why MP exists

Three concrete benefits drive MP's design:

- **Automatic reformulation.** Problems containing expressions a solver doesn't natively
  support (conditional logic, counting operators, complementarity, and more — see
  `expressions-and-modeling-guide.md`) can still be solved through an MP-based driver: the
  interface transforms the expression into a form the underlying solver accepts, without
  the modeler having to hand-linearize it first.
- **Consistency.** Many solver options are implemented once at the framework level (see
  `feature-and-solver-options-guide.md`) rather than per solver, so an individual driver
  only needs to implement the corresponding API hook. This keeps option naming and
  semantics consistent across solvers — `outlev`, `lim:time`, `mipgap`, and similar options
  behave the same way regardless of which MP-based solver is active.
- **Speed of driver development.** Declarative, modern design patterns mean a typical MIP
  solver driver can be coded in a few days rather than a much longer bespoke integration
  effort — this matters less to modelers directly, but it's part of why the list of
  MP-based solvers below keeps growing.

## Which solvers use MP, and what MP does for each class

Solvers built with MP accept a much wider range of model expressions than the solver's own
API: you write the model the way you think about it, and MP passes each construct to the
solver natively where the solver supports it, and reformulates it otherwise. What happens
to a construct depends on the solver class:

| Class | MP-based drivers | What MP does |
|---|---|---|
| Linear and mixed-integer | `gurobi`, `cplex`, `xpress`, `copt`, `highs`, `scip`, `mosek`, `cbc`, `gcg`, `cuopt` | Logic becomes indicator or general constraints where the solver has them, big-M rows otherwise; other nonlinear functions are approximated piecewise-linearly |
| Conic | MOSEK, COPT, Gurobi, Xpress, CPLEX, SCIP | Recognizes second-order and exponential cones from their algebraic form |
| Global nonlinear | Gurobi, Xpress, SCIP, BARON (`baronmp`); COPT solves nonlinear models locally (`acc:_expr=1`) | Passes nonlinear functions as expression trees |
| Constraint programming | CP-SAT (integer models) | Receives logic, counting, `alldiff`, products, `div` and `mod` natively. The same constructs are reformulated for MIP solvers, so a CP model can also be solved by any MIP solver |
| Any NL solver | MP2NL (e.g. Knitro, Ipopt, Couenne, BARON) | Applies MP's reformulations, then calls the NL solver |

The exact list of what an installed driver receives natively is printed by its acceptance
options (`<solver> -=acc:`) and compared across drivers in
`tools-troubleshooting-and-reformulation.md` ("Native constraints and expressions by
driver"). For every other AMPL solver (Knitro, Ipopt, CONOPT, the legacy
`gurobiasl`/`cplexasl`/`xpressasl` drivers, and so on), **MP2NL** applies MP's
reformulations and then calls the solver; Knitro, BARON, CONOPT and LINDO Global have it
built in (`mp2nl=1`). See `tools-troubleshooting-and-reformulation.md`, and
`../core-language/13-solver-selection-guide.md` for the full capability picture.

Two other driver families exist in the `ampl/mp` repository:

- **Old-API expression-based drivers** map the NL model directly onto the solver's API
  without MP's reformulations: `ilogcp` (IBM ILOG CPLEX and CP Optimizer), `gecode`, and
  the unmaintained `jacop` and `localsolver`. For constraint programming *with* MP's
  reformulations, use CP-SAT.
- **Specialized drivers:** an SOCP solver built on CPLEX (`cplexsocp`), an SSD solver for
  second-order stochastic dominance constraints, and `smpswriter`, which converts the
  deterministic equivalent of a two-stage stochastic program to SMPS format.

Binaries for MP-based solvers are distributed through the AMPL Portal
(`https://portal.ampl.com`), individually or in bundles. Solver options and features are
documented in `feature-and-solver-options-guide.md` and, per solver, at AMPL Development
(`https://dev.ampl.com/solvers/index.html`), whose solver pages summarize the problem types
and expressions each one receives natively.

## What MP handles

The expanded interface recognizes AMPL syntax in more general contexts than the classic
ASL-based interpretation — most notably, variables inside conditional, logical and
counting constructs. Each category is covered in `expressions-and-modeling-guide.md`:

| Category | Representative syntax |
|---|---|
| Conditional and logical constraints | `if-then-else`, `==>`, `<==`, `<==>`; `or`, `and`, `not`, `exists`, `forall` |
| Counting and constraint-programming constructs | `count`, `atmost`, `atleast`, `exactly`, `numberof`, `alldiff`, `!=` |
| Piecewise-linear functions | `<<breakpoints; slopes>>`, `abs`, `min`, `max` |
| Rounding and integer division | `floor`, `ceil`, `round`, `trunc`, `div`, `mod` |
| Nonlinear functions and products; cones | `*`, `/`, `^`, `exp`, `log`, trigonometric/hyperbolic functions; second-order and exponential cones |
| Complementarity | `complements` |
| Set membership | `in` (being reworked — see `expressions-and-modeling-guide.md`) |
| Multiple objectives | see `multi-objective-optimization.md` |

These aren't new AMPL syntax — they're existing AMPL constructs that MP-based solver
interfaces can now accept in places (and combinations) that earlier ASL-based drivers
either rejected or required the modeler to reformulate manually.

**This updates/extends, rather than duplicates, the AMPL book's treatment of these
constructs** — per the source manifest's documented conflict note, where the book and MP
describe the same construct, MP is the more current source for anything
solver-interface-related (expression handling, piecewise-linear/logical/complementarity
operators, solver option naming), while the book remains authoritative for core language
syntax MP doesn't redefine (sets, params, `.dat` files, scripting). Specific supersession
notes are called out inline in the relevant `mp-library/` files below — e.g.
`expressions-and-modeling-guide.md`'s piecewise-linear section against
`../modeling-patterns/piecewise-linear-programs.md`.

## Where to go next

This file is the entry point for the `mp-library/` folder. From here:

- **Modeling with the expanded syntax** — every operator category above, with worked
  examples: `expressions-and-modeling-guide.md`
- **Multiple objectives** — blended and lexicographic (hierarchical) objectives,
  per-objective solver options: `multi-objective-optimization.md`
- **Getting solvers to perform well and reliably** — formulation choices that speed up
  solving, plus coefficient/bound scaling for numerical stability:
  `efficiency-and-numerical-accuracy.md`; choosing between whole formulations (big-M,
  indicators, known reformulations): `../modeling-patterns/choosing-formulations.md`
- **Looking under the hood** — flat constraints vs. expression trees, the Reformulation
  Explorer, automatic solution checking, exporting the solver's model, the MP2NL
  meta-driver, and general troubleshooting steps:
  `tools-troubleshooting-and-reformulation.md`; reading results and comparing runs:
  `../benchmarking-and-validation.md`
- **Solver options and features mechanically** — how `<solver>_options`/`mp_options` work,
  solve result codes, and which solvers support which features (feasibility relaxation,
  IIS, warm start, multiple solutions, etc.): `feature-and-solver-options-guide.md`

## See also

- Solver capability matrix and picking a starting point:
  `../core-language/13-solver-selection-guide.md`
- Presolve, `solve_result` codes, and suffix mechanics in general (not MP-specific):
  `../core-language/11-solver-interaction-and-suffixes.md`
- Per-solver curated option guides for tuning a specific solver once chosen:
  `../solver-options/` (referenced here; consult it for solver-specific tuning rather than
  duplicating that content in this folder)
