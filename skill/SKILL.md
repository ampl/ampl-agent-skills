---
name: ampl-skill
description: Use this skill for ANY task involving AMPL (A Mathematical Programming Language) — writing, reading, fixing, or explaining .mod/.dat/.run files; formulating or reformulating optimization models (LP, MIP, NLP, piecewise-linear, network, complementarity); working with amplpy (the Python API) or ampls (the low-level solver-callback API); debugging AMPL syntax errors, infeasible/unbounded solves, nonlinear solver failures, or unexpected results; choosing between AMPL modeling patterns; or answering "how do I express X in AMPL" questions. Trigger this skill whenever AMPL, amplpy, or ampls is mentioned, whenever a .mod/.dat/.run file is involved, or whenever the user is formulating a mathematical program and AMPL is a plausible implementation target — even if they don't name AMPL explicitly but describe sets/parameters/variables/constraints in an optimization context.
---
v3.0.1
# AMPL Modeling Language

## What this skill covers

Comprehensive reference material for AMPL: the core language (syntax, sets, data,
commands, scripting, solver interaction), classic and advanced modeling patterns (LP,
network, columnwise, piecewise-linear, nonlinear, complementarity, integer/MIP), the
Python ecosystem (`amplpy` for everyday scripting, `ampls` for solver-native callback
access), the MP solver-interface library (expanded expressions, multi-objective solving,
reformulation tooling), curated per-solver tuning guides, a worked end-to-end tutorial,
and licensing/deployment FAQs. Content is written for OR/optimization practitioners of
all levels — beginners get runnable examples and plain-language explanations; advanced
users get precise syntax tables, edge-case gotchas, and cross-references to the exact
section of the AMPL book or AMPL/MP documentation a topic comes from.

## When to use this skill

Reach for this skill for essentially anything AMPL-shaped:

- Writing a new `.mod`/`.dat`/`.run` file, or extending an existing one.
- Translating a mathematical formulation (sets, indices, constraints) into AMPL syntax.
- Choosing a modeling pattern — e.g. "should this be `node`/`arc` or algebraic
  `var`/`subject to`," "should this cost be piecewise-linear or a binary fixed-cost
  trick," "does this need integer variables at all."
- Reformulating for speed: "why is my MIP/logical model slow," "should this be an
  indicator or a big-M," "is the convex hull worth it," "is there a better formulation
  for this structure" — see `references/modeling-patterns/choosing-formulations.md`.
- Building a heuristic around a model: "evaluate a candidate," "fix the integers and
  solve the rest," "rolling horizon," "relax and round," "my heuristic does not beat
  doing nothing" — see `references/modeling-patterns/model-as-evaluator-and-heuristics.md`.
- Solving a model with logical or complementarity constraints through a classic NL
  solver (MP2NL): "which options go where," "the NLP solver says optimal but the logic is
  violated" — see `references/mp-library/tools-troubleshooting-and-reformulation.md`.
- Comparing formulations or solvers, or deciding whether a result can be trusted: "is
  this optimal," "which formulation is faster," "the solver says infeasible but..." —
  see `references/benchmarking-and-validation.md`.
- Debugging: a syntax error, an infeasible/unbounded solve, a nonlinear solver that fails
  or returns implausible numbers, a MIP that won't solve in reasonable time, output that
  doesn't match expectations.
- Writing or reviewing `amplpy` code (loading models/data, solving, retrieving results)
  or `ampls` code (callbacks, lazy constraints, solver-native access).
- Explaining what a piece of existing AMPL code does.
- Style/naming questions for a model meant to be read by others.

## Default recommendations

Absent other direction from the user, default to these — they reflect how AMPL is meant
to be used in practice, not just what's technically possible:

- **Use an API, not interactive/script-mode AMPL.** The recommended way to use AMPL is
  through one of its APIs — Python, R, C#, C++, C, Java, or MATLAB — not by driving AMPL
  directly with `.run` scripts and the interactive prompt. In practice: keep the model
  itself in a `.mod` file, and do everything else — loading data, setting options,
  solving, retrieving/printing results, control flow — through the API. This means
  `.dat` and `.run` files are **not** the default for new work; they're still documented
  in full (`references/core-language/06-data-files-and-formats.md`,
  `references/core-language/10-scripting-and-control-flow.md`,
  `references/tutorials-and-examples/worked-example-tutorial.md`) because you'll need
  them to read/debug existing pure-AMPL projects, but don't reach for them by default
  when starting something new.
- **Default to Python (`amplpy`).** Of the available APIs, Python is the recommended
  default. Unless the user specifies a different language (or is clearly already working
  in one), write and suggest Python/`amplpy` code rather than pure AMPL scripts or
  another language's API — see `references/amplpy/`.
- **For solver choice**, see `references/core-language/13-solver-selection-guide.md` for
  a quick problem-class → solver lookup (LP/MIP, QP, conic, non-convex, MINLP, general
  NLP, global optimization, GPU-accelerated).
- **Prefer MP-based solver drivers over legacy ASL drivers where both exist** (Gurobi,
  CPLEX, Xpress). MP is AMPL's newer solver-interface layer — see `references/mp-library/`
  for what it adds and `references/solver-options/` for per-solver tuning written against
  MP-interface option names by default.

## How to use this skill

1. **Identify the topic area** from the table below and open the matching file(s) in
   `references/`. Most tasks need only one or two files — the folders are organized so
   you rarely need to read the whole skill.
2. **For syntax lookups** ("what's the exact form of X"), go straight to
   `references/core-language/12-syntax-quick-reference.md` — it's a dense table-only
   companion to the narrative chapters.
3. **For "how do I model X"** questions, check `references/modeling-patterns/` first —
   these files are organized by problem shape (network, piecewise-linear, integer, ...),
   not by book chapter, and each includes a "when to reach for this" framing plus
   worked, adapted (not copy-pasted) examples.
4. **For Python workflows**, use `references/amplpy/` for everyday scripting (the default
   — see "Default recommendations" above) and `references/ampls/` only when the task
   specifically needs mid-solve control (callbacks, lazy constraints) or solver-native
   access — most amplpy tasks don't need ampls at all.
5. **For "which solver should I use"**, go to
   `references/core-language/13-solver-selection-guide.md`. Once a solver is chosen, for
   "how do I tune/configure it," go to `references/solver-options/`.
6. **For MP-specific questions** ("what does the MP interface add," expanded expression
   syntax, multi-objective solving, reformulation/solution-check tooling), use
   `references/mp-library/` — start at `overview-and-when-to-use.md`.
7. **Cross-references**: every reference file ends with a "See also" section pointing to
   related files — follow these rather than assuming a topic is fully covered by the
   first file you open.

## Reference map

### `references/core-language/` — the language itself, in reading order

| File | Covers |
|---|---|
| `01-language-basics.md` | Lexical rules, entity declarations, comments, statement structure |
| `02-style-and-best-practices.md` | Naming conventions (by entity type), model structure, comments, `check` statements |
| `03-sets-and-indexing.md` | Set declarations, indexing expressions, ordered sets, set operators |
| `04-parameters-and-expressions.md` | Parameter declarations, arithmetic/logical expressions, recursive definitions |
| `05-variables-objectives-constraints.md` | `var`/`minimize`/`maximize`/`subject to` declarations, bounds, defined variables |
| `06-data-files-and-formats.md` | `.dat` file syntax: lists, tables, templates for sets and parameters |
| `07-database-access-and-tables.md` | AMPL's native `table`/`read table`/`write table` (ODBC, text/binary handlers) |
| `08-commands-modifying-models-and-data.md` | `let`, `fix`/`unfix`, `drop`/`restore`, `delete`/`purge`/`redeclare`, `reset` |
| `09-display-and-output-commands.md` | `display`, `print`/`printf`, `show`/`xref`/`expand`, generic `_var`/`_con`/`_obj` synonyms |
| `10-scripting-and-control-flow.md` | Scripts, `for`/`repeat`/`if`, string functions, introspection sets (`_PARS`, `_VARS`, ...) |
| `11-solver-interaction-and-suffixes.md` | Presolve, `solve_result`, statuses, suffixes, named problems/environments |
| `12-syntax-quick-reference.md` | **Dense lookup tables**: reserved words, operator precedence, built-in functions, suffix tables, command list, `printf` specifiers, invocation options |
| `13-solver-selection-guide.md` | "Which solver should I use" — quick lookup by problem class (LP/MIP, QP, conic, non-convex, MINLP, NLP, global, GPU), sourced from AMPL's solver capability matrix |
| `14-ampl-options-reference.md` | Core (non-solver-specific) `option` settings: display/formatting, presolve, solve, execution, file, library, misc — **not** solver tuning (see `../solver-options/` for that) |

### `references/modeling-patterns/` — how to model specific problem shapes

| File | Use when |
|---|---|
| `classic-lp-patterns.md` | Basic production/blending/diet-style LP formulation patterns |
| `network-models.md` | Flow/transportation/assignment/shortest-path problems; `node`/`arc` syntax |
| `columnwise-formulations.md` | A variable's coefficients (not a constraint's) have the simple pattern — `to_come`, `coeff`, `obj`, `cover` |
| `piecewise-linear-programs.md` | Tiered/volume-dependent costs, penalty terms, backordering; the `<<...>>` notation |
| `nonlinear-programs.md` | Genuinely smooth nonlinear objectives/constraints; NLP pitfalls (range violations, local optima) |
| `nlp-formulation-choices.md` | **Choosing between nonlinear formulations**: substitute (defined variables) vs. keep a named variable, coordinate systems and problem class (test, no universal winner), redundant convex constraints on lifted quantities, consistent starting points, smooth stand-ins for nonsmooth laws (MP guide + field measurements) |
| `model-as-evaluator-and-heuristics.md` | **Heuristics built on the model**: fix the discrete decisions and solve the rest, one evaluator, elastic (L1-penalty) ranking of infeasible candidates, the status-quo baseline, rolling horizon with `fix`/`drop`, checking a relaxation is informative before relax-and-round / RENS (amplpy best practices + field measurements) |
| `complementarity-problems.md` | Economic/physical equilibria; the `complements` operator |
| `integer-programming.md` | Integer/binary variables; fixed costs, thresholds, cardinality limits via 0/1 variables |
| `choosing-formulations.md` | **Choosing between formulations** of a MIP or logical model — the single home for this topic: declared bounds and big-M sizing, indicators vs. big-M, logic and the relaxation, known formulations (time-indexed, assignment, perspective, convex hull, facets), set membership vs. disjunction, strength vs. size, root-bound and other pre-benchmark checks (MP guide "Choosing between formulations" + field measurements) |

### `references/amplpy/` — Python API

| File | Use when |
|---|---|
| `getting-started-and-installation.md` | Installing amplpy/solvers, licensing, Colab/Jupyter setup, Docker containers |
| `core-workflow-best-practices.md` | Loading models/data, solving and checking the status, retrieving/exporting results, error/warning handling, iterative algorithms — everyday scripting |
| `api-reference-classes.md` | Method-by-method reference for `AMPL`, `Entity`, `Variable`, `Constraint`, `Objective`, `Set`, `Parameter`; methods added in amplpy 0.15.1–0.18.0 |

### `references/ampls/` — low-level solver-callback API (advanced)

| File | Use when |
|---|---|
| `overview-and-architecture.md` | Deciding whether you actually need `ampls` (vs. staying in `amplpy`) |
| `usage-and-quickstart.md` | Installing; the three usage levels (generic/solver-specific/solver-native) in code |
| `api-reference-classes.md` | `AMPLModel`, `GenericCallback`, `GurobiModel`, `CPLEXModel` method reference |
| `callbacks-and-examples.md` | Worked patterns: stopping criteria, lazy constraints (TSP subtour elimination), user cuts, column generation |

### `references/mp-library/` — MP, AMPL's newer solver-interface library

| File | Use when |
|---|---|
| `overview-and-when-to-use.md` | What MP is, solver classes and what MP does for each (incl. the CP-SAT constraint-programming driver), other driver families, which solvers use MP2NL — **start here** |
| `expressions-and-modeling-guide.md` | The expanded syntax MP understands: conditional/logical/counting operators, piecewise-linear, `complements`, rounding and integer division, products, conic (SOCP/exponential cones), general nonlinear functions by solver class |
| `multi-objective-optimization.md` | `obj:multi`, blended vs. lexicographic/hierarchical objectives, nonlinear objectives, per-objective solver options, pass statistics |
| `efficiency-and-numerical-accuracy.md` | Reformulating for solver performance (common subexpressions, subexpression bounds, declared bounds set big-M); tight coefficients, big-M sizing, counting changes of a continuous variable, piecewise-linear numerical stability |
| `tools-troubleshooting-and-reformulation.md` | Flat constraints vs. expression trees, `acc:` acceptance options and which drivers receive which constructs natively, exporting the solver model, Reformulation Explorer, automatic solution checking, MP2NL in practice, troubleshooting steps |
| `feature-and-solver-options-guide.md` | How AMPL/MP solver options work mechanically, solve result codes, the 13-driver feature-support matrix, solution export, fixed-model emulation, plateau stop and how its rule works — the bridge to `../solver-options/` |

### `references/solver-options/` — curated per-solver tuning (not exhaustive)

Each file covers the options practitioners actually reach for — autotuner, MIP stopping
criteria, variable/branch selection, numerical-issue tolerances, cuts, and
concurrent/algorithm selection — with a pointer to the raw source and original URL for
the complete option list. Use `references/core-language/13-solver-selection-guide.md` first to
pick a solver, then come here to tune it.

| File | Covers |
|---|---|
| `gurobi-options.md` | Gurobi (MP-interface names, ASL aliases noted where relevant) |
| `xpress-options.md` | Xpress (MP names, complete source; note the 2026 removal of the `xprs_`/`xslp_` name prefixes) |
| `cplex-options.md` | CPLEX (MP-interface names, ASL aliases noted where relevant) |
| `copt-options.md` | COPT (MP-interface only — no separate ASL driver; tuner available since October 2026) |
| `highs-options.md` | HiGHS (MP-interface only — no separate ASL driver; no autotuner or cut-family controls exposed) |
| `cbc-options.md` | CBC (MP driver; native `double:`/`int:` parameters; LP/MILP only) |
| `cuopt-options.md` | NVIDIA cuOpt (MP driver; GPU LP/MILP, PDLP modes) |
| `scip-options.md` | SCIP (MP driver; open-source global MINLP; emphasis and preset groups) |
| `knitro-options.md` | Knitro (non-MP driver with built-in MP2NL bridge; local NLP/MINLP, multistart) |
| `ipopt-options.md` | IPOPT (non-MP driver; keyword list grouped by purpose, no defaults in the source) |
| `mp2nl-options.md` | MP2NL meta-driver: the `nl:` family, generic options passed on, complementarity reformulations |

### `references/tutorials-and-examples/`

| File | Use when |
|---|---|
| `worked-example-tutorial.md` | End-to-end walkthrough: concrete model → warm-starting → parametric generalization → multi-instance solving |
| `cross-language-api-equivalents.md` | Translating an AMPL API call between Python/R/C++/C#/Java; installing each API and where its docs are |
| `model-library-netlib.md` | Pointers into the public Netlib AMPL model archive for additional examples |
| `mp-library-reference-models.md` | Four small runnable models (multi-objective diet, two infeasible models — the IIS one now linear, n-Queens) used as worked examples across `../mp-library/` and `../solver-options/` |

### `references/troubleshooting-and-faqs.md`

Licensing, installation, Docker deployment, cloud-license mechanics. **Not** a
model-debugging guide — for that, see the pitfalls/gotchas embedded in
`modeling-patterns/nonlinear-programs.md`, `core-language/11-solver-interaction-and-suffixes.md`,
and `core-language/09-display-and-output-commands.md` (linked from this file too).

### `references/benchmarking-and-validation.md`

Reading solver results correctly and comparing formulations, solvers or heuristics
fairly — the single home for this topic: what a status claims (a local "optimal", a
`limit` that returned the starting point), cross-checking every dual bound against every
incumbent, validating a reformulation (independent references, the sign check), pairing
on instances, seeds and performance variability, and experimental design (MP guide
"Reading solver results" / "Comparing formulations and solvers" + field measurements).

## Known gaps / flagged content

- `ampls/api-reference-classes.md` notes that source examples mix `camelCase` and
  `snake_case` method names across different code samples — both may be valid depending
  on installed version; check the installed package if one form errors.
- `tutorials-and-examples/cross-language-api-equivalents.md` was reconstructed from a
  flattened multi-language source table; a few language attributions were inferred
  heuristically — flagged inline where this applies.
- `ampls/callbacks-and-examples.md` draws partly on an ASR (speech-to-text) webinar
  transcript with known mishearings — cross-checked against accompanying example code,
  but treat exact wording as reconstructed, not quoted.
- Five reference files combine AMPL documentation with developer field measurements:
  `modeling-patterns/choosing-formulations.md`, `modeling-patterns/nlp-formulation-choices.md`,
  `modeling-patterns/model-as-evaluator-and-heuristics.md`,
  `benchmarking-and-validation.md`, and the "Iterative algorithms" section of
  `amplpy/core-workflow-best-practices.md`. Most of their rules and many of their figures
  are now in the MP modeling guide and the amplpy best-practices page (named in each
  file's "Derived from" line); figures that appear in no AMPL page are marked as field
  measurements. Numbers illustrate direction and size, not guarantees for a particular
  solver or version.
- The "Default recommendations" section above is **editorial guidance, not drawn from
  AMPL documentation**; if AMPL's API recommendations change, current AMPL docs take
  precedence. The same holds for the "Picking a starting point" section of
  `core-language/13-solver-selection-guide.md` (its capability matrix is sourced from
  AMPL's solver pages).
- `solver-options/cuopt-options.md` flags a discrepancy in the source: the cuOpt page's
  example uses `cuopt_options`, the driver's own option header says `cuoptmp_options`.
  `solver-options/knitro-options.md` flags that `mp2nl` is not in the Knitro option list
  although the MP documentation uses `knitro_options 'mp2nl=1'`.
- The amplpy class reference is built from the 0.15.0 documentation; methods added in
  0.15.1–0.18.0 are listed from the release changelog only (no signatures beyond what the
  changelog shows).
- The `solver-options/` files are **deliberately not exhaustive** — each raw solver
  options file is a 5-280KB generated CLI dump; the distilled files cover only the
  options practitioners commonly tune (autotuner, MIP stopping, branch selection,
  numerical tolerances, cuts, concurrent/algorithm selection) plus a pointer to the raw
  file and original URL for anything not covered.

See `raw/sources.md` (in this skill's raw source layer, not part of the distributed
skill) for the full source manifest, original URLs, and known data-quality notes per
source.
