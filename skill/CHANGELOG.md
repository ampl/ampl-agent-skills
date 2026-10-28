# Changelog

## [3.0.1] - 2026-10-28

### Fixed
- Removed maintenance-history notes from reference text (CPLEX, Gurobi, Xpress, COPT,
  HiGHS options; solver selection guide; feature guide; amplpy best practices; reference
  models; cross-language table; `SKILL.md` known gaps). Facts they carried:
  - CPLEX: earlier skill versions wrongly claimed a `tech:optionnative` option.
  - Xpress: earlier skill versions cited ASL names for the `mip:`-onward categories
    (MP source was truncated).
  - Solver selection guide, 2026-10-28: CBC QP/MIQP ✅→❌, HiGHS (MI)QCP ❌→≈, GCG
    quadratic/nonlinear ✅→≈/❌.
  - Feature table re-extracted 2026-10-28 (now 13 columns).
  - amplpy best-practices page passed `mipfocus` via `mp_options` until October 2026.
  - Option counts at the 2026-10-28 re-fetch: CPLEX 295→373, Gurobi 352→390, COPT
    229→274, HiGHS 206→248.
  - MP reference models: the infeasible example was a nonlinear `log`/`exp` model until
    October 2026.
- `mp-library-reference-models.md`: "current as of" date set to the 2026-10-28 re-fetch.
- `copt-options.md`: stale "227 top-level options" count removed.

## [3.0.0] - 2026-10-28

### Changed
- Consolidated the developer's 2.1.0/2.1.1 changes with the 2026-10-28 raw update (24
  sources re-fetched, 17 added).
- **Renamed** `modeling-patterns/mip-formulation-practice.md` → `modeling-patterns/choosing-formulations.md`
  (counterpart of `raw/mp-choosing-between-formulations.md`); all links updated.
- Single home per topic: choosing formulations → `choosing-formulations.md`; reading
  results and comparing runs → `benchmarking-and-validation.md`; substitute-or-name and
  redundant convex rows → `nlp-formulation-choices.md`; other files point there.
- "Derived from" lines of the developer's four files and the iterative-algorithms
  section now name their raw sources; figures in no AMPL page marked as field measurements.
- `mp-library/`: overview rewritten around solver classes (CP-SAT, other driver
  families); expressions (indicator recovery, multi-solver native AND/OR/abs/min/max/PL,
  CP-SAT native constructs, integer products, rounding/`div`/`mod`, solver-class table);
  efficiency (declared bounds set big-M, counting changes, `cvt:pl:domain`); tools
  (native-constructs-by-driver table replaces the constraint ID list; export with names;
  pointers to checks); feature guide (grouped important features, 13-column support
  table, solution export, fixed-model emulation, plateau stopping rule); multi-objective
  (nonlinear objectives, pass statistics).
- `solver-options/`: Xpress rewritten from the complete source (prefix-free names);
  Gurobi, CPLEX, COPT, HiGHS updated to the October option lists.
- `core-language/13-solver-selection-guide.md`: CBC, HiGHS, GCG rows corrected; CP and
  complementarity solvers added.
- `amplpy/`: status checking, `mp_options` vs. solver-specific keywords, sensitivity
  sweep, warnings (`_throw_on_warnings`); Docker; methods added in 0.15.1–0.18.0.
- `SKILL.md`: version 3.0.0, reference map and known gaps updated.

### Added
- `solver-options/`: `cbc-options.md`, `cuopt-options.md`, `scip-options.md`,
  `knitro-options.md`, `ipopt-options.md`, `mp2nl-options.md`.
- Suffix reference additions (objective/problem suffixes, `.defeqn`/`.defvar`) in
  `core-language/11` and `12`; `xor` operator; `times_file` option; API install table;
  ampls version notes.

### Fixed
- `choosing-formulations.md`: perspective root-gap figure made consistent (99 %); forall
  implication described for current MP (old 16.7 % kept as a version note).
- `core-workflow-best-practices.md`: unsupported "wrong results" claim replaced by the
  upstream structural guidance; `mipfocus` belongs in `gurobi_options`.
- `cplex-options.md`: removed nonexistent `tech:optionnative` (and a Gurobi parameter
  example); `mir` → `mircuts`. `highs-options.md`: plateau example now sets `abstol`
  with `reltol`. `mp-library-reference-models.md`: infeasible model matches the MP page.

## [2.1.1] - 2026-10-27

### Changed
- `modeling-patterns/mip-formulation-practice.md`: updated with new measurements (an
  implication with a `forall` consequent gives the same root bound as the expanded form
  in current MP versions; a constraint on a single variable acts as a bound); the
  root-bound check uses the solver option `relax=1` and the solver-reported objective;
  perspective with a semicontinuous declaration.
- `amplpy/core-workflow-best-practices.md`: how the default error handler treats warnings
  (raised in `eval`, printed in `solve`); an unsuccessful solve does not raise; dropping
  selected constraint instances.
- `mp-library/tools-troubleshooting-and-reformulation.md`: MP2NL in practice (where options
  go, choosing a subsolver for the class after reformulation, `cvt:compl`, configurations,
  statuses).

### Added
- Links to worked examples on the AMPL Model Colaboratory (https://colab.ampl.com/tags/
  `big-m`, `perspective`, `fix-and-solve`, `mp2nl`) and to the corresponding sections of
  the MP modeling guide.

## [2.1.0] - 2026-10-27

### Added
Reference files based on measured modeling experience (benchmark studies of logical and
hand-linearized MIP/MINLP formulations, and an NLP-based heuristic for discrete-control
scheduling on public power-network benchmarks), with the literature cited inline:
- `references/modeling-patterns/mip-formulation-practice.md` — declared bounds and big-M
  sizing, indicators vs. big-M, logic that may not reach the relaxation, known
  formulations (time-indexed, assignment, perspective incl. its piecewise-linear form,
  convex hull, facets), strength vs. size, cheap pre-benchmark checks.
- `references/modeling-patterns/nlp-formulation-choices.md` — substitute vs. name
  (reduced vs. full space) with a switch pattern, coordinates and problem class as a
  choice to benchmark, redundant convex constraints on lifted quantities, starting
  points, smoothing.
- `references/modeling-patterns/model-as-evaluator-and-heuristics.md` — fix-and-solve
  evaluation, elastic ranking of infeasible candidates, the status-quo baseline, rolling
  horizon with `fix`/`drop`, checking a relaxation is informative before rounding.
- `references/benchmarking-and-validation.md` — what a status claims, bound/incumbent
  cross-checks, validating a reformulation, paired comparisons, seeds, experimental
  design, failure records.
- "Iterative algorithms" section in `references/amplpy/core-workflow-best-practices.md`.

### Changed
- `SKILL.md`: reference-map rows and "When to use" triggers for the new files.
- "See also" links from `integer-programming.md`, `nonlinear-programs.md`,
  `efficiency-and-numerical-accuracy.md`, `08-commands-modifying-models-and-data.md` and
  `11-solver-interaction-and-suffixes.md`.

## [2.0.2] - 2026-08-26

### Changed
- `raw/mp-expressions-supported.md` re-fetched: MP flags Set membership
  (`in set-expr`/`interval[...]`) as under rework, recommending disjunctive
  constraints (`||`) instead — new example added. See `raw/sources.md`.
- `references/mp-library/expressions-and-modeling-guide.md` updated to match.

## [2.0.1] - 2026-08-20

### Added
- One-line `Derived from: <raw filenames>` traceability note added at the top of all 44
  reference files, listing the raw/ source(s) each was distilled from.

## [2.0.0] - 2026-08-17

### Added
- New `references/mp-library/` subfolder (6 files): `overview-and-when-to-use.md`,
  `expressions-and-modeling-guide.md`, `multi-objective-optimization.md`,
  `efficiency-and-numerical-accuracy.md`, `tools-troubleshooting-and-reformulation.md`,
  `feature-and-solver-options-guide.md` — covers AMPL's MP solver-interface library
  (expanded expression syntax, multi-objective solving, numerical-accuracy guidance,
  reformulation/solution-check tooling, MP2NL).
- New `references/solver-options/` subfolder (5 files): curated, non-exhaustive per-solver
  tuning guides for Gurobi, Xpress, CPLEX, COPT, HiGHS — autotuner, MIP stopping criteria,
  variable/branch selection, numerical-issue tolerances, cuts, concurrent/algorithm
  selection, each pointing to its raw source and original URL for the full option list.
- New `references/core-language/14-ampl-options-reference.md` — core (non-solver-specific)
  AMPL `option` settings: display/formatting, presolve, solve, execution, file, library,
  misc.
- New `references/tutorials-and-examples/mp-library-reference-models.md` — four small
  runnable models (multi-objective diet, two infeasible models, n-Queens) used across the
  new mp-library/ and solver-options/ content.
- 20 new raw sources added to `raw/`: 10 MP library pages (`mp.ampl.com`) and 10 AMPL/solver
  options pages (`dev.ampl.com`) — see `raw/sources.md` for the full list.

### Changed
- `core-language/13-solver-selection-guide.md` rewritten to source its capability matrix
  from `raw/solvers-index.md` (`https://dev.ampl.com/solvers/index.html`) instead of
  purely editorial guidance; expanded with separate linear-quadratic and nonlinear-solver
  tables. Its "Picking a starting point" section remains editorial synthesis (see
  `SKILL.md`'s "Known gaps").
- `SKILL.md` reference map, "How to use this skill," and "Default recommendations"
  updated to route to the new `mp-library/` and `solver-options/` content; "Known gaps"
  updated accordingly.

### Fixed
- N/A

### Flagged (see `raw/sources.md` and `SKILL.md` "Known gaps" for detail)
- `raw/xpress-mp-options.md` is incomplete (fetch-tool capture limit) — covers `acc:`
  through `log:xprs_maxpagelines` only. `solver-options/xpress-options.md` substitutes
  ASL-interface option names for the missing categories, flagged inline. Not pursued
  further per explicit instruction — revisit if a browser-based fetch becomes available.
- `mp-library/feature-and-solver-options-guide.md`'s "support by solvers" table was
  reconstructed from a fragmented HTML-table fetch — cross-check individual cells against
  the live page before relying on one for a solver decision.

## [1.0.1] - 2026-08-16

### Changed
- Renamed skill from `ampl-modeling-language` to `ampl-skill` (SKILL.md and folder name).

## [1.0.0] - 2026-08-16

### Added
- SKILL.md and 31 reference files (core-language, modeling-patterns, amplpy, ampls, tutorials-and-examples, troubleshooting-and-faqs).
- Default recommendations (API-first, Python/amplpy default) and solver selection guide.

### Fixed
- Full review of basic-scripting.md; added missing content (CLI options table, filtered `let`, `reset` vs `reset data`, batch-solve pattern).
