# amplpy API Reference: AMPL, Entity, Variable, Constraint, Objective, Set, Parameter

Derived from: release-amplpy-changelog.md (newer methods), amplpy-ampl-class.md, amplpy-entity.md, amplpy-variable.md, amplpy-constraint.md, amplpy-objective.md, amplpy-set.md, amplpy-parameter.md

Source: `amplpy-ampl-class.md`, `amplpy-entity.md`, `amplpy-variable.md`,
`amplpy-constraint.md`, `amplpy-objective.md`, `amplpy-set.md`, `amplpy-parameter.md`.

This is a condensed method reference, not a tutorial — see `core-workflow-best-practices.md`
for task-oriented usage patterns and worked examples. Merged into one file because these
seven classes are small, tightly interrelated (four of them subclass `Entity`), and are
typically looked up together while reading amplpy code.

## Table of contents

- `AMPL`: the session/translator object
- `Entity`: shared base for Variable/Constraint/Objective/Set/Parameter
- `Variable`, `Constraint`, `Objective`: suffix-backed result accessors
- `Set`, `Parameter`: data accessors
- Newer than the 0.15.0 documentation

## `AMPL`

The top-level session object; one instance per running AMPL interpreter.

```python
from amplpy import AMPL
ampl = AMPL(environment=None)     # environment: custom AMPL binary location / env vars
```

**Loading model/data:**

| Method | Purpose |
|---|---|
| `read(filename)` | interpret a file (model, script, or mixed) |
| `read_data(filename)` | interpret a `.dat` file; returns to model mode afterward |
| `eval(statements)` | interpret an AMPL statement/declaration string directly |
| `read_table(name)` / `write_table(name)` | equivalent to `read table name;` / `write table name;` |
| `set_data(dataframe, set_name=None)` | assign a DataFrame's columns to matching-named AMPL entities |

Both `read()` and `eval()` **invalidate all cached entity handles** as a side effect
(since arbitrary commands could have changed anything) — entity lists are re-populated
lazily on next access, not eagerly, so don't assume a `Variable`/`Constraint` object
obtained before a `read()`/`eval()` call is still valid without re-fetching it.

**Accessing entities**, singly or as full collections — `get_variable(name)` /
`get_variables()`, `get_constraint(name)` / `get_constraints()`, `get_objective(name)` /
`get_objectives()`, `get_set(name)` / `get_sets()`, `get_parameter(name)` /
`get_parameters()`, plus `get_entity(name)` (searches across all types) and
`get_current_objective()`. Property-style shortcuts exist for the common cases:
`ampl.var[...]`, `ampl.con[...]`, `ampl.obj[...]`, `ampl.param[...]`, `ampl.set[...]`,
`ampl.option[...]` — all get/settable by index. A missing name raises `KeyError`, not a
silent `None`.

**Solving and results:**

| Method | Purpose |
|---|---|
| `solve(problem='', solver='', verbose=True, return_output=False, **kwargs)` | run the solve; `kwargs` pass `solvername_options` |
| `solve_result` / `solve_result_num` | outcome, as string / numeric code (same ranges as `../core-language/11-solver-interaction-and-suffixes.md`) |
| `get_solution(flat=True, zeros=False)` | dictionary of all variable values |
| `get_iis(flat=True)` | Irreducible Infeasible Subsystem, as (var dict, con dict) tuples |
| `get_data(*statements)` | equivalent of `display` for arbitrary expressions, returned as one DataFrame — fails if the statements don't share a common index shape |
| `get_value(scalar_expression)` | a single scalar value (double or string) from an arbitrary AMPL expression |

**Options and I/O:** `get_option(name)` / `set_option(name, value)` (raises on an invalid
option name or wrong-typed value); `get_error_handler()` / `set_error_handler(...)` (AMPL
translator errors/warnings — default behavior: exceptions on error, console print on
warning); `get_output_handler()` / `set_output_handler(...)` (routes translator output,
e.g. for capturing to a log instead of stdout); `display(*expressions)` (writes formatted
output via the current OutputHandler — the Python-side equivalent of the AMPL `display`
command); `get_output(statements)` (like `eval()` but returns the output as a string
instead of routing it through the handler); `export_model(filename)` /
`export_data(filename)` / `snapshot(filename, model=True, data=True, options=True)`
(dump the current model/data/options back out to files — `snapshot` is the "reproduce
this exact session" option); `cd(path=None)` (get/set working directory); `write(filename,
auxfiles='')` (invoke the `write` command); `reset()` (clear everything — model, data,
cached entities); `close()` (stop the underlying engine; further calls raise); `to_ampls(driver, options=None)`
(hand off to the lower-level `ampls` driver API — see `../ampls/` for that layer).

## `Entity`

Base class for `Variable`, `Constraint`, `Objective`, `Set`, `Parameter`. Represents
either one scalar instance or, if the underlying AMPL declaration is indexed, a mapping
from index tuples to instances.

| Method | Purpose |
|---|---|
| `get(*index)` / `entity[key]` | fetch one instance by its index tuple |
| `find(index)` | like `get`, but returns `None` instead of raising if not found |
| `instances()` | iterate over all instances |
| `is_scalar()` | `True` iff `indexarity() == 0` |
| `indexarity()` | sum of dimensions of the indexing sets — the arity of the tuple `get()` expects |
| `num_instances()` | count of instances |
| `name()` | the entity's AMPL name |
| `get_indexing_sets()` | string representation of the entity's indexing sets |
| `get_values(suffixes=None)` | DataFrame of principal values (or specified suffixes) across all instances |
| `set_values(dataframe)` | assign from a DataFrame indexed over a matching (or subset) index — equivalent to `let {s in S} x[s] := y[s];` |
| `to_dict()` / `to_list()` / `to_pandas()` | convenience wrappers around `get_values()` |
| `xref()` | names of all entities that depend on this one |

`indexarity()` worked examples: `var x;` → 0, `var y{1..2};` → 1, `var z{1..2,3..4};` → 2,
`var zz{{(1,2)}};` → 2 (a single 2-tuple set still has arity 2, not 1) — the count is the
*sum of index-set dimensions*, not the number of separate indexing clauses.

`get_values()`'s default (no `suffixes` argument) differs meaningfully by entity type:
Variables/Objectives → `.val`; Parameters → their raw value; Constraints → `.dual`; Sets →
their members (non-indexed sets only). Know this default before assuming `get_values()`
always means "the value" in the same sense across entity types.

## `Variable`, `Constraint`, `Objective`: suffix-method mapping

Each of these subclasses `Entity` and exposes AMPL's built-in suffixes
(`../core-language/11-solver-interaction-and-suffixes.md`, or the full tables in
`../core-language/12-syntax-quick-reference.md`) as identically-named Python methods —
learn the suffix once in AMPL terms and the Python method name follows directly, e.g.
`.lb` → `variable.lb()`, `.dual` → `constraint.dual()`. Calling one of these methods on a
non-scalar entity raises `TypeError` (index into it first, e.g. `Buy['CHK'].lb()`, or
operate on the whole entity via `get_values()`); calling it on a deleted entity raises
`RuntimeError`.

**`Variable`** (suffix methods): `value()`, `lb()`/`ub()` (current), `lb0()`/`ub0()`
(original declared), `lb1()`/`ub1()` / `lb2()`/`ub2()` (post-presolve, weaker/stronger),
`rc()` (reduced cost at nearer bound), `lrc()`/`urc()` (at lower/upper bound
specifically), `slack()`/`lslack()`/`uslack()`, `init()`/`init0()` (current / original
initial guess), `astatus()`/`sstatus()`/`status()`, `dual()` (of the defining constraint,
if substituted out), `defeqn()` (index of that defining constraint). Action methods (not
suffix reads): `fix(value=None)` (fix to given or current value), `unfix()`,
`set_value(value)` (equivalent to AMPL `let`, does **not** fix the variable — a common
point of confusion versus `fix()`).

**`Constraint`** (suffix methods): `body()`, `lb()`/`ub()`, `lbs()`/`ubs()` (bound as
adjusted/sent to the solver), `dual()`, `ldual()`/`udual()`, `slack()`/`lslack()`/`uslack()`,
`dinit()`/`dinit0()` (dual initial guess, current/original), `astatus()`/`sstatus()`/`status()`,
`is_logical()` (algebraic vs. logical constraint — some suffixes only apply to one kind),
`val()` (logical constraints only), `defvar()` (index of the variable this constraint
defines, if it's a substituted-out defining constraint). Action methods: `drop()` /
`restore()`, `set_dual(value)` (equivalent to `let c := dual;`).

**Note on dual-value resets**: dual values are frequently reset by AMPL's own presolve
machinery as a side effect of other method calls — if you need a dual value to persist
exactly as set, consider `ampl.option['presolve'] = 0` as a workaround (trades away
presolve's simplification benefits, so use narrowly).

**`Objective`**: `value()`, `minimization()` (`True` if `minimize`, `False` if
`maximize`), `astatus()`/`sstatus()`, `exitcode()`/`message()`/`result()` (solver's raw
exit code / message / result string from the most recent solve involving this
objective), `drop()`/`restore()`.

## `Set` and `Parameter`

**`Set`**: iterate directly (`for member in my_set: ...`) or index into an *indexed*
collection of sets (`my_set[key]`) to get one instance. `arity()` (components per member),
`contains(tuple)`, `members()` (all tuples — non-indexed sets only), `get_values()` /
`set_values(values)` (list of tuples or a DataFrame; non-indexed sets only — for indexed
set collections, address each instance and assign individually), `size()` (member count,
non-indexed only).

**`Parameter`**: `value()` (scalar parameters only), `is_symbolic()` (declared
`symbolic` — can hold strings, not just numbers), `has_default()` (true even if the
default expression itself references an undefined parameter — a subtlety worth knowing
before relying on this check to mean "will resolve to a concrete value"), `set(*args)`
(assign one instance: just a value if scalar, else index-then-value), `set_values(values)`
(bulk-assign from a list/dict/DataFrame — equivalent to
`let {i in indices} par[i] := values[i];`; raises `TypeError` if called on a scalar
parameter — use `set()` instead for scalars).

## Newer than the 0.15.0 documentation

The class pages this file was built from document amplpy 0.15.0. The release changelog
lists additions since then (check `amplpy.__version__` before relying on them):

| Version (date) | Addition |
|---|---|
| 0.15.1 (2025-06-20) | AMPL option `_throw_on_warnings` controls whether warnings raise exceptions |
| 0.16.0 (2025-12-08) | type hints; Python 3.14 / 3.14t support |
| 0.17.0 (2026-06-24) | `AMPL.expand()`, `AMPL.show()`; `Entity.expand()` (instance-level when indexed) |
| 0.18.0 (2026-07-21) | `AMPL.reset_options()`; `Entity.set_suffix(suffix, value)` (number/string for scalar instances, DataFrame/Series for indexed entities) |

These are listed from the changelog only; their signatures beyond what is shown here are
not in the raw corpus yet.

## See also

- Task-oriented usage of these classes (loading data, solving, exporting results):
  `core-workflow-best-practices.md`
- The underlying AMPL suffixes these Python methods mirror, in full narrative form:
  `../core-language/11-solver-interaction-and-suffixes.md`
- The lower-level `ampls` driver API (`AMPL.to_ampls()`), for direct solver-object access
  beyond what `amplpy` exposes: `../ampls/`
