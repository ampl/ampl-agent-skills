# Commands: Setup, Solving, and Modifying Models/Data

Derived from: ampl-book.md (ch. 11), basic-scripting.md

Source: *AMPL: A Modeling Language for Mathematical Programming*, 2nd ed., Chapter 11.

## The command environment, in brief

- Every command ends in `;`; an incomplete line gets a continuation prompt (`ampl?` instead of
  `ampl:`).
- AMPL is always in either **model mode** or **data mode**. `data;` (no filename) enters data
  mode at the prompt; `model;` (no filename), or any command that isn't a data statement
  (`display`, `solve`, `option`, ...), returns to model mode. A `model`/`data` command *with* a
  filename reads that file in the corresponding mode, then reverts to whatever mode was active
  before.
- **Options** are name/value settings (`option display_width 79;`) with no master list — AMPL
  accepts any name you give it, so a typo silently creates a new, inert option instead of
  erroring. `option name;` (no value) queries the current value; `*` is a wildcard
  (`option cplex_options*;`); `reset options;` restores all defaults. This mechanism also
  configures solver-specific behavior (e.g. `option cplex_options 'mipgap=0.01';`) — see
  `11-solver-interaction-and-suffixes.md`.

## Setting up and solving

```
ampl: model diet.mod; data diet.dat; solve;
```

- `model`/`data` commands are additive — you can call each multiple times to assemble a model
  or data set from several files (or from statements typed directly).
- If a model has more than one objective, use `objective Name;` (or `objective Name[index];`
  for an indexed collection) to select which one `solve` optimizes — otherwise most solvers
  default to the first declared.
- `solve` does, in order: generate the concrete problem instance from model+data (data
  validation/`check` failures surface here, not at `data` time) → **presolve** (may tighten
  bounds, fold constraints, or detect infeasibility outright, printed as a `presolve:` message)
  → hand off to the solver named by `option solver;` → retrieve results.
- Switch solvers with `option solver <name>;`. **`reset;` between solves** if you want to
  compare solvers on identical starting conditions — otherwise the previous solve's solution
  state carries over and can bias a warm-started solver.
- A message like "ignoring integrality" or "can't handle nonlinearities" means the chosen
  solver doesn't support a feature your model uses — not a modeling bug.

## Modifying data without touching the model

**`let`** — the everyday tool for one-off or small-batch "what if" data changes:

```
ampl: let f_max["CHK"] := 11;
ampl: let {j in FOOD} f_max[j] := 1.1 * f_max[j];    # indexed form -- apply to every member
```

Anything not defined by an `=` phrase in the model can appear on the left of `let`'s `:=`
— including **variables** (handy for exploring/rounding a solution by hand, e.g.
`let {j in FOOD} Buy[j] := floor(Buy[j]);`, after which dependent quantities like the objective
and constraint slacks recompute automatically). Rounding helpers: `ceil`, `floor`,
`round(x[,n])`, `trunc(x[,n])`, `precision(x,n)`.

The indexing expression accepts the same `: condition` filter as any other set
comprehension, which makes a filtered `let` a compact one-liner for "update only the
entries that need it" — e.g. the LP-relaxation warm-start idiom (round every variable
that solved to a non-integer value, leave the rest alone):
```ampl
let {i in 1.._nvars : _var[i] != round(_var[i])} _var[i] := round(_var[i]);
```
Equivalent to, but more compact than, a `for` loop with an `if` test inside
(`../tutorials-and-examples/worked-example-tutorial.md`, Stage 3).

**Caution**: changing a parameter that other parameters/sets are indexed over (e.g. shrinking a
horizon parameter `T` after data for `1..T` was already loaded) leaves stale, now-invalid
subscripted values behind and produces `invalid subscript` errors at the next `solve`. The fix
is to separate the *declared/loaded* range from the *currently active* range:
```ampl
param Tdata integer > 0;              # index params/data over 1..Tdata (fixed, matches loaded data)
param T integer <= Tdata;             # index vars/objective/constraints over 1..T (freely adjustable via let)
```

**`reset data [names];`** wipes the named components' data entirely (or *everything* if no
names given) so you can supply fresh values via a new `data` command; also forces a fresh draw
for any randomly-computed parameters (`04-parameters-and-expressions.md`). Bare `reset;` (no
`data`) additionally resets AMPL's random-number generator itself, so random parameters repeat
their original sequence instead of advancing.

**`update data [names];`** is the gentler version of `reset data` — it doesn't clear anything
until you actually supply a replacement value, so components you forget to re-supply just keep
their old values instead of becoming undefined.

## Modifying the model itself

| Command | Effect |
|---|---|
| `delete c1, c2, ...;` | remove objective(s)/constraint(s) by name (only if nothing else depends on them) |
| `purge c1, c2, ...;` | like `delete`, but cascades to everything that depends on them, directly or indirectly |
| `xref c1, c2, ...;` | list what depends on the named component(s) — run before `purge` if unsure of blast radius |
| `redeclare <full new declaration>;` | replace one component's declaration in place (e.g. tighten a bound) without disturbing dependents or previously-loaded data |
| `drop con-list;` / `restore con-list;` | temporarily exclude/re-include constraints (or an indexed subset) from the next `solve`, cumulative across calls |
| `fix var-list [:= expr];` / `unfix var-list;` | pin variable(s) at their current (or given) value as if by an equality constraint; reverse it |
| `reset;` | wipe the entire current model *and* data (options untouched) — equivalent to restarting, minus config |

`delete`/`purge`/`redeclare` only apply to objectives and constraints, not to sets, parameters,
or variables that other declarations still reference — `redeclare` is usually what you actually
want for "just change this one thing" (e.g. `redeclare param f_min {FOOD} > 0 integer;`
tightens a restriction without disturbing anything downstream).

`drop`/`restore` and `fix`/`unfix` share the same syntax pattern: command keyword, optional
indexing expression, then a (possibly subscripted) name:

```ampl
drop Diet_Max["CAL"];
drop {i in MAXNOT} Diet_Max[i];       # drop a subset
fix {j in FOOD: amt["NA",j] > 1200} Buy[j] := f_min[j];   # fix + assign in one statement
```

## Relaxing integrality

```
ampl: option relax_integrality 1;    # global: ignore ALL integer/binary restrictions
ampl: let Buy['CHK'].relax := 1;     # per-variable: relax just this one
```

**Prefer AMPL's `relax_integrality`/`.relax` over a solver's own "relax" directive** when the
two might disagree — AMPL drops the integrality restriction *before* presolve when you use
`relax_integrality`, so presolve reasons about the true continuous relaxation; if instead the
solver does the relaxing internally, AMPL's presolve has already tightened bounds *assuming*
integrality (e.g. rounding a `9.5` upper bound down to `9`), so the two relaxations can produce
measurably different — and easily misinterpreted — optimal values. This is a documented, real
gotcha, not a hypothetical edge case: see the worked before/after example in the source chapter
if a solver-side relaxation and AMPL-side relaxation appear to disagree.

## See also

- Using `fix`/`drop` to evaluate candidate decisions and to solve rolling-horizon
  windows on one model: `../modeling-patterns/model-as-evaluator-and-heuristics.md`
- Diagnosing infeasibility, presolve internals, solve results/statuses, suffixes:
  `11-solver-interaction-and-suffixes.md`
- Output/display commands and formatting options: `09-display-and-output-commands.md`
- Doing this repeatedly/programmatically (loops, scripts): `10-scripting-and-control-flow.md`
- Integer/binary modeling implications: `../modeling-patterns/integer-programming.md`
