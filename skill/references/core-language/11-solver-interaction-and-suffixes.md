# Solver Interaction: Presolve, Solve Results, Suffixes, Named Problems

Derived from: ampl-book.md (ch. 14), ampl-suffixes.md

Source: *AMPL: A Modeling Language for Mathematical Programming*, 2nd ed., Chapter 14.

## Table of contents

- Presolve: what it does, how to inspect/control it, infeasibility detection
- Solve results (`solve_result`, `solve_result_num`, `solve_message`, `solve_exitcode`)
- Solver statuses of variables/constraints (`.sstatus`), AMPL statuses (`.astatus`), `.status`
- Suffixes: built-in, user-defined (`IN`), solver-defined (`OUT`) — sensitivity, IIS, unboundedness
- Named problems and environments (alternating between models in a script)

## Presolve

Presolve runs automatically on every `solve`, tightening variable bounds and eliminating
provably-redundant variables/constraints before the problem reaches the solver — usually
invisible, always reversible (the *displayed* solution is in terms of your original model).

```
ampl: option show_stats 1;      # before solve: print size before/after presolve
ampl: solve;
Presolve eliminates 2 constraints and 2 variables.
```

Find exactly what got eliminated via the `pre` status (see AMPL statuses below):
```
ampl: print {j in 1.._nvars: _var[j].status = "pre"}: _varname[j];
```

- Typical eliminations: a single-variable equality constraint (fixes and removes the variable);
  a constraint provably implied by variable bounds (e.g. a `<=` constraint whose LHS can never
  exceed the bound even at every variable's upper limit).
- `option presolve 0;` disables presolve entirely; `1` disables only the iterative
  bound-tightening (second) phase; a higher number caps the number of tightening passes
  (default 10).
- Two sets of post-presolve bounds are kept: `.lb1`/`.ub1` (from eliminated constraints only)
  and `.lb2`/`.ub2` (further tightened via surviving constraints). `option var_bounds 2;`
  (default 1) tells AMPL to send the more-tightened set to the solver — can help or hurt
  depending on solver/algorithm; `.lb0`/`.ub0` are the original, pre-presolve bounds.
- **Integer variable bound rounding**: fractional deduced bounds get rounded to the nearest
  integer, but floating-point noise (`7.00000000001`) could round the wrong direction — AMPL
  applies a small epsilon (`presolve_inteps`, default `1e-6`, capped by `presolve_intepsmax`,
  `1e-5`) before rounding to guard against this.
- **Infeasibility caught at presolve** prints an explicit `presolve: constraint ... cannot
  hold` message with the conflicting bound values and their difference — this is often *more*
  informative than a bare "infeasible" from the solver, since it names the specific constraint
  and shows the numeric gap. If the gap is tiny (floating-point noise near a true equality),
  `option presolve_eps <value>;` (default `0`) tells presolve to ignore differences below that
  threshold rather than declaring infeasibility; a related `presolve_fixeps` /
  `presolve_fixepsmax` pair fixes a variable/constraint body at the midpoint when its bound gap
  is small-but-positive, to spare the solver needless work on a near-degenerate case. AMPL
  suggests a concrete threshold value in its message when relevant
  (`Setting $presolve_eps >= 6.86e-07 might help.`).
- Typing `solve` again right after a presolve-detected infeasibility message sends the
  seemingly-inconsistent bounds to the solver anyway — useful to see how the solver's own
  feasibility tolerance handles a borderline case.

## Solve results: testing what happened, programmatically

```
ampl: display solve_result_num, solve_result, solve_message, solve_exitcode;
```

| Parameter | Meaning |
|---|---|
| `solve_result_num` | integer status code, ranges are solver-defined but conventionally: 0-99 solved, 100-199 solved? (error likely), 200-299 infeasible, 300-399 unbounded, 400-499 hit a limit, 500-599 failure |
| `solve_result` | short string version of the same (`solved`, `infeasible`, `unbounded`, `limit`, `failure`, or `?` before any solve) |
| `solve_message` | the exact text the solver printed at termination — parse with string functions (`10-scripting-and-control-flow.md`) if you need finer distinctions than `solve_result` gives |
| `solve_exitcode` | 0 = solver process ran successfully; nonzero = AMPL couldn't even invoke the solver (misspelled name, licensing, missing temp-dir write permission, etc.) — check this *before* trusting `solve_result` |

`option solve_result_table;` shows the current code→string mapping (solver-driver-defined).
This is the standard pattern for a script that must branch on outcome (see the sensitivity-sweep
example in `10-scripting-and-control-flow.md`):

```ampl
solve;
if solve_result = "infeasible" then { printf "--- infeasible ---\n"; break; }
```

`option solver_msg 0;` silences the solver's own termination banner (handy in tight loops);
`solve_message` still captures the text even when display is suppressed.
`option solve_exitcode_max 0;` (default) means AMPL aborts any enclosing
`for`/`repeat`/`if`/`include`/`commands` block the moment a solver invocation fails outright.

## Statuses: solver (`.sstatus`) vs. AMPL (`.astatus`) vs. combined (`.status`)

- **`.sstatus`** (variables) / constraint `.sstatus` (via the associated slack/artificial
  variable) — the *solver's* basis status: `bas` (basic), `low`/`upp` (nonbasic at lower/upper
  bound), `equ` (nonbasic, bounds equal), `sup` (superbasic, nonlinear solvers), `btw`
  (nonbasic between bounds), `none` (nothing solved yet). Numeric form: `.sstatus_num`.
  **Reusing a prior basis speeds up re-solves dramatically** — `option send_statuses 1;`
  (the default) automatically feeds the previous solve's statuses back as a warm start;
  disabling it (`0`) forces every re-solve to start from scratch, which is occasionally useful
  for benchmarking but usually just slower.
- **`.astatus`** — whether/why a component was excluded from what got sent to the solver at
  all: `in` (sent normally), `drop` (removed by `drop`), `pre` (eliminated by presolve), `fix`
  (fixed by `fix`), `sub` (substituted-out defined variable), `unused` (not referenced by any
  active objective/constraint).
- **`.status`** — the practically useful one: equals `.sstatus` when `.astatus` is `in`,
  otherwise falls back to `.astatus`. Use this suffix when you just want "what happened to
  this component," not the full solver-vs-AMPL distinction.

## Suffixes: the general mechanism

Any `name.suffix` you've seen so far (`.lb`, `.rc`, `.dual`, `.slack`, ...) is an instance of
AMPL's general suffix mechanism (full built-in list in `12-syntax-quick-reference.md`
/ Appendix A.11). You can also define **new** suffixes for exchanging solver-specific
information — either directions *you* send to the solver, or extra results the solver sends
back that AMPL has no built-in name for.

```ampl
suffix priority IN, integer, >= 0, <= 9999;    # user-defined: values YOU set, solver reads them
suffix iis symbolic OUT;                        # solver-defined: solver sets values, you read them
```

Qualifiers (any order): `IN` (AMPL→solver only), `OUT` (solver→AMPL only), `INOUT` (both,
default), `LOCAL` (neither — pure bookkeeping); type `integer`/`binary`/`symbolic`
(default: any numeric); `>=`/`<=` bound expressions. A `symbolic` suffix auto-creates a
matching `_num` numeric suffix plus expects an `option <suffix>_table` mapping codes to
strings (as shown by the solver driver's own auto-generated `suffix ... ;`/`option ..._table`
messages after a relevant `solve`).

**Common real examples** (solver- and feature-specific, but illustrate the pattern):

```ampl
# Send CPLEX MIP branching hints (user-defined, IN)
suffix priority IN, integer, >= 0, <= 9999;
suffix direction IN, integer, >= -1, <= 1;
let {i in ORIG, j in DEST} Use[i,j].priority := sum {p in PROD} demand[j,p];

# Read CPLEX sensitivity ranges after `option cplex_options 'sensitivity';` + solve (solver-defined, OUT)
display Sell.down, Sell.current, Sell.up;      # objective-coefficient range keeping current basis optimal
display Time.down, Time.current, Time.up;      # same idea, for a constraint's RHS

# Read an Irreducible Infeasible Subset after `option cplex_options 'iisfind 1';` + solve on an infeasible problem
print {i in 1.._ncons: _con[i].iis <> "non"}: _conname[i];

# Read a direction of unboundedness for an unbounded LP
display Supply_Price.unbdd;
```

A suffix used by a solver is typically **defined automatically by that solver's driver** the
first time it's relevant (AMPL echoes the auto-generated `suffix ...;` statement) — you don't
need to declare it yourself unless you reference it *before* the triggering `solve`, e.g. inside
a `repeat` loop that's fully parsed before execution begins:
```ampl
suffix unbdd OUT;     # declare up front so a later reference inside a loop body doesn't error
repeat { solve Sub; ... let x[i] := Var[i].unbdd; ... }
```
This is a real, documented gotcha: AMPL scans an entire compound statement (`for`/`repeat`/`if`)
before executing any of it, so a solver-defined suffix that would only be created by a `solve`
*inside* the loop isn't recognized yet when the loop body is parsed.

**Which custom suffixes does a solver support?** AMPL cannot anticipate them all; they
depend on each solver's design. Study the solver's options: for example, the Gurobi
options `obj:multi:options`, `mip:lazy` and `cvt:sos` control how the corresponding
suffixes are interpreted (`../mp-library/feature-and-solver-options-guide.md` lists the
suffix-based MP features: lazy constraints, priorities, feasibility-relaxation penalties,
IIS, sensitivity, multi-objective options).

**Presolve and suffixes.** AMPL presolve can eliminate variables and change constraints,
which interferes with custom and built-in suffixes. When suffix values matter, switch it
off with `option presolve 0;`.

Suffix values can also be assigned inline in a `var` declaration:
```ampl
var Use {i in ORIG, j in DEST} binary, suffix priority sum {p in PROD} demand[j,p];
```

## Alternating between models: `problem` and `environ`

For scripts that need to switch between genuinely different sub-models repeatedly (column
generation, Benders/Dantzig-Wolfe decomposition, Lagrangian relaxation), naming subsets of
components as **problems** is far cleaner and more efficient than manually juggling
`fix`/`unfix`/`drop`/`restore` before every `solve`.

```ampl
problem Cutting_Opt: Cut, Number, Fill;             # name a subset: vars, objective(s), constraints
option relax_integrality 1;                          # this option setting attaches to Cutting_Opt's environment
problem Pattern_Gen: Use, Reduced_Cost, Width_Limit;
option relax_integrality 0;
...
repeat {
   solve Cutting_Opt;                                 # make current + solve, in one step
   let {i in WIDTHS} price[i] := Fill[i].dual;         # sets/params are ALWAYS global, regardless of current problem
   solve Pattern_Gen;
   if Reduced_Cost < -0.00001 then { ... } else break;
}
```

- A `problem Name: comp, comp, ...;` declaration: unfixes/restores everything listed (making it
  active) and fixes/drops everything else — i.e. makes that problem's components the only ones
  sent to the solver, without you managing `fix`/`drop` by hand.
- Every variable/objective/constraint belongs to the implicit problem `Initial` until you
  partition things explicitly. `problem;` alone reports the current problem name; `show
  problems;` lists all named problems; `show Name;` lists a problem's members; `expand Name;`
  shows its fully-instantiated objective/constraints.
- **Sets and parameters are always global** — this is precisely how you pass information (like
  a dual price) from one named sub-problem to another between solves.
- An **environment** is the companion concept for *option* values (as opposed to model
  components): each named problem gets its own environment by default (same name), remembering
  whatever `option` settings were active when it was created/last modified — so
  `option relax_integrality 1;` issued right after defining `Cutting_Opt` "belongs" to that
  problem and is restored automatically every time `Cutting_Opt` becomes current again. Declare
  environments independently with `environ Name;`, or attach an existing one to a problem with
  `problem Name environ EnvName: ...;`, when you want option-sets to be shared or organized
  differently from the problem partition itself.
- `redeclare problem Name: ...;` replaces a problem's member list outright (can't be used inside
  a compound statement); `reset problem Name;` reverts to the list from its original
  declaration.
- Indexed collections of problems are supported (`problem SubII {p in PROD}: ...;`), addressed
  the normal subscripted way (`problem SubII["coils"];`, or `solve SubII["coils"];`).

## See also

- What a status does and does not claim (local optimality, a `limit` returning the
  starting point), and cross-checking results across solvers:
  `../benchmarking-and-validation.md`
- `let`, `fix`/`unfix`, `drop`/`restore` mechanics: `08-commands-modifying-models-and-data.md`
- Reading duals/reduced costs/slacks day-to-day: `09-display-and-output-commands.md`
- Scripting constructs (`for`/`repeat`/`if`) used to build alternating-model loops:
  `10-scripting-and-control-flow.md`
- Full built-in suffix tables (A.11): `12-syntax-quick-reference.md`
- "Which solver should I use for this problem class": `13-solver-selection-guide.md`
