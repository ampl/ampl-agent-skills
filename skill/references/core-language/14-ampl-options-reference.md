# AMPL Options Reference

Derived from: ampl-options.md, release-ampl-changelog.md

Source: `raw/ampl-options.md` (`https://dev.ampl.com/ampl/reference/options.html`),
current as of 2026-08-17. This file covers **core AMPL options** — the ones that govern
AMPL's own behavior (formatting, presolve, execution, files). It is deliberately kept
separate from `../solver-options/`, which covers each *solver's* tuning options
(`gurobi_options`, `cplex_options`, etc.) — those are a different mechanism (strings
passed to a specific solver) from the options on this page (set directly with `option`).

Type key: `b` = 0 or 1, `n` = integer, `r` = any number, `s` = character string.

## Setting and inspecting options

```ampl
ampl: option print_separator, display_width;   # show current values
ampl: option print*;                           # wildcard: show all print_* options
ampl: option display_width 60, print_separator ', ';   # set one or more options
ampl: reset options;                           # restore all defaults
```

`option *` (or `option` alone) lists every current option and value. AMPL does not
validate option names — a typo (`display_wdith`) silently creates a new, meaningless
option rather than erroring, so double-check spelling with `option <name>*` after
setting something unfamiliar. String values needing quotes: `'...'` or `"..."`; `''`/`""`
is an explicit empty string; trailing `\` continues a string onto the next line.
Environment variables with the same name as an option are read at AMPL startup and
override the built-in default.

## Display command options

Affect only the *formatting* of `display` output, not AMPL's internal record of values.

| Option | Type (default) | Effect |
|---|---|---|
| `display_1col` | n (20) | One column if param count <= n, else multi-column (0 = force multi, huge = force one) |
| `display_eps` | r (0) | Magnitude below which a value displays as 0 |
| `display_max_2d_cols` | n (0) | Max columns before a 2-D table splits (0 = no limit) |
| `display_precision` | n (6) | Significant digits shown (0 = full/shortest exact precision) |
| `display_round` | n ("") | Digits relative to decimal point; overrides `display_precision` when set |
| `display_set_1col` | n (0) | Same as `display_1col` but for set displays |
| `display_transpose` | n (0) | Transpose 2-D tables when rows − cols < n |
| `display_width` | n (79) | Max characters per output line |
| `gutter_width` | n (3) | Spaces between columns |
| `omit_zero_cols` | b (0) | Hide all-zero columns |
| `omit_zero_rows` | b (0) | Hide all-zero rows |

## Other formatting options

Same idea as above, for `csvdisplay`, `expand`, `print`, and `-M`/`-D` command-line
output; not AMPL's internal record.

| Option | Type (default) | Effect |
|---|---|---|
| `csvdisplay_header` | b (1) | Emit a header line in csvdisplay output |
| `csvdisplay_precision` | n (0) | Like `display_precision`, for csvdisplay/`_display` |
| `csvdisplay_restrict` | n ("") | 1/3 = error if csvdisplay is asked to show >1 table |
| `csvdisplay_round` | n ("") | Like `display_round`, for csvdisplay/`_display` |
| `expand_precision` | n (0) | Like `display_precision`, for `expand` output |
| `expand_round` | n ("") | Like `display_round`, for `expand` output |
| `format_range_errmsg` | s (" ") | Out-of-range placeholder for `%i/%d/%o/%u/%x/%X` in printf/sprintf; empty = error + abort instead |
| `MD_precision` | n (0) | Like `display_precision`, for `-M`/`-D` CLI listings |
| `print_precision` | n (0) | Like `display_precision`, for `print` |
| `print_round` | n ("") | Like `display_round`, for `print` |
| `print_separator` | s (" ") | Separator between `print` values |

## Presolve options

Presolve removes redundant one-variable inequalities, tightens bounds, fixes variables,
and drops constraints before a problem reaches the solver.

| Option | Type (default) | Effect |
|---|---|---|
| `presolve` | n (10) | Max presolve passes; 0 disables presolve entirely |
| `presolve_eps` | r (0) | Feasibility tolerance: infeasible only if lb exceeds ub by more than this |
| `presolve_epsmax` | r (1e-5) | Warn if raising `presolve_eps` up to this value would change results |
| `presolve_fixeps` | r (0) | Fix a variable/constraint to the bound average when bounds differ by less than this |
| `presolve_fixepsmax` | r (1e-5) | Warn threshold for `presolve_fixeps` changes, analogous to `presolve_epsmax` |
| `presolve_inteps` | r (1e-6) | Integrality tolerance when tightening integer variable bounds |
| `presolve_intepsmax` | r (1e-5) | Warn threshold for `presolve_inteps` changes |
| `presolve_assoc` | n (7, sum) | 1=simplify via +/− associativity, 2=via */÷ associativity, 4=via distributivity |
| `presolve_logfile` | s ("") | File to log presolve actions (`>>` prefix appends; `-` = stdout) |
| `presolve_warnings` | n (5) | Max number of presolve warning messages shown |
| `project_fixed_vars` | n (1) | 1 = snap an out-of-bounds fixed variable to nearest bound; 0 = widen the bound instead; 2 = also message each projection |
| `show_presolve_messages` | b (1) | Set 0 to suppress trivial/infeasible presolve messages |
| `infeas_clear` | n (1) | Whether solve/write may proceed after presolve finds infeasibility: 0=never, 1=only on a 2nd manual solve, 2=also in scripts, 3=always |
| `var_bounds` | n (1) | 1 = send bounds from eliminated constraints only; 2 = also incorporate bounds from surviving constraints (tighter, but can add degeneracy). Suffixes `.lb1/.ub1`, `.lb2/.ub2`, `.lb/.ub` expose both sets plus whichever was sent |
| `constraint_drop_tol` | r (0) | Roundoff-related presolve tuning — see `https://www.netlib.org/ampl/fixlog` |

## Solve options

Govern `solve`/`write` and what's sent to the solver.

| Option | Type (default) | Effect |
|---|---|---|
| `solver` | s | Solver executable name; searched on PATH if not a full path |
| `auxfiles`, `(solver)_auxfiles` | s ("") | Auxiliary name files to write: `a`=.adj, `c`=.col, `e`=.env, `f`=.fix, `p`=.spc (MINOS), `r`=.row, `s`=.slc, `u`=.unv. `auxfiles` affects `write`; `(solver)_auxfiles` affects `solve` with that solver |
| `dual_initial_guesses` | b (1) | Send current dual values as a warm start |
| `reset_initial_guesses` | b (0) | 1 = reset variables to model-specified initial values instead of sending current ones |
| `send_statuses` | b (1) | Send `.sstatus` basis info to the solver (useful for warm-starting simplex) |
| `send_suffixes` | n (3, sum) | 1=send suffixes to solver, 2=receive from solver, 3=both (default) |
| `linelim` | b (1) | Eliminate linear defined variables by substitution (else solver sees them as nonlinear) |
| `substout` | b (0) | Convert eligible `var = expr` constraints into defined variables |
| `nl_comments` | b (0) | Add debugging comments to written `.nl` files |
| `nl_permute` | n (3, sum) | 1=permute constraints, 2=permute variables, 4=permute objectives (nonlinear-first ordering some solvers require) |
| `outopt` | s ("") | Argument implied by a bare `write` command |
| `output_precision` | n (0) | Significant digits AMPL uses writing numbers to the solver's problem file (0 = full precision) |
| `pl_bigM` | r (1e6) | Big-M bound assumed around a piecewise-linear function's breakpoints during linearization |
| `pl_linearize` | b (1) | 1 = linearize `<<...;...>>` piecewise-linear expressions before sending to solver; 0 = send as nonlinear expressions (**recommended 0 for MP-based solvers** — see `../mp-library/expressions-and-modeling-guide.md`) |
| `relax_integrality` | b (0) | 1 = solve the continuous relaxation (integer/binary vars become continuous) |

## Solve message options

| Option | Type (default) | Effect |
|---|---|---|
| `solver_msg` | b (1) | Show the solver's brief result summary |
| `show_stats` | n (0) | 1 = presolve summary + var/constraint/nonzero counts; 2 = more detail |
| `show_write_files` | n (0) | 0=never report written filename, 1=only if set indirectly via `outopt`, 2=always |
| `times` | b (0) | Detailed time/memory stats for major AMPL execution phases |
| `gentimes` | b (0) | Detailed time/memory stats per model component (sets, params, vars, objs, cons) |
| `times_file` | s ('') | File to which `times`/`gentimes` output is appended (since AMPL 20260723). Default `''` keeps it on stderr — except under APIs such as amplpy, where `times`/`gentimes` output is no longer sent to stderr and goes to this file |
| `bad_subscripts` | n (3) | Max number of invalid index-combination errors reported |
| `compl_warn` | n (1) | Warn on non-square complementarity systems; 0=off, 2=also treat as infeasible |
| `strict_ineq_warn` | n (1) | How to handle `>`/`<` constraints: 1=warn + represent as logical constraint (default), 0=silent, 2=error + reject |

## Result options

| Option | Type (default) | Effect |
|---|---|---|
| `objective_precision` | n (10) | Significant digits shown for the objective value in the solver result message |
| `solution_precision` | n ("") | Rounds returned primal/dual values to n significant digits **before storing in AMPL** (affects all downstream use, not just display) |
| `solution_round` | n ("") | Like `solution_precision` but digits relative to the decimal point; overrides it when set |
| `abs_boundtol`, `rel_boundtol` | r (0) | Absolute/relative tolerance for whether a presolve-eliminated constraint counts as tight (affects deduced dual values) |
| `boundtol_max` | r (1e-5) | Threshold above which a `abs_boundtol`/`rel_boundtol` change is reported |
| `show_boundtol` | b (1) | Whether to report `boundtol_max`-triggering changes at all |

## Execution options

| Option | Type (default) | Effect |
|---|---|---|
| `allow_NaN` | b (0) | 1 = numerical errors (div-by-0, log of negative) return NaN instead of erroring; doesn't affect solver-side handling |
| `ampl_include` | s (".") | Directory searched for `model`/`data`/`include`/`commands` files |
| `Cautions` | n (1) | 0=suppress caution messages, 1=show (default), 2=treat as errors |
| `cmdtrace` | b (0) | Echo each command executed (plus file/line when read from a file) |
| `eexit` | n (-10) | n<0: abort current statement after \|n\| messages; n>0: abort session after n messages; 0=show all |
| `single_step`, `single_step_cmdno` | n (0) | Interactive single-step script debugging (step/skip/next/cont/end) |
| `solve_exitcode_max` | n (0) | Abort running compound commands if `solve_exitcode` exceeds this (0 = any failed solve aborts) |
| `shell_exitcode_max` | n (65536) | Abort running compound commands if a `shell` command's exit code exceeds this |
| `shell_exitignore` | n (0) | Suppress the shell "exit code e" message when e < n |
| `stdin_offset` | b (0) | Report input offset/command number in errors when reading from stdin |

## File options

| Option | Type (default) | Effect |
|---|---|---|
| `log_file` | s ("") | Destination log file for subsequent commands/responses |
| `log_model`, `log_data` | b (0) | Also echo model-mode / data-mode statements (incl. included files) to the log |
| `OPTIONS_IN` | s ("") | File of option statements executed at startup (requires the matching env var set before AMPL starts) |
| `OPTIONS_OUT` | s ("") | File that current option values are written to at shutdown |
| `OPTIONS_INOUT` | s ("") | Combines both: read at startup, current values written back at shutdown; read after `OPTIONS_IN`, before `OPTIONS_OUT` |
| `shell_env_file` | s ("") | File that current options are dumped to before running a `shell` command |
| `TMPDIR` | s ("") | Directory for temporary `.nl`/`.sol` files (empty = system default) |

## Library options

| Option | Type (default) | Effect |
|---|---|---|
| `AMPLFUNC`, `ampl_funclibs` | s ("") | External function libraries in use (normally auto-set) |
| `ampl_libpath` | s | Search directory for external function libraries (normally auto-set) |
| `libmap_32_64` | b (1) | How 32-bit/64-bit library variants are resolved |
| `load_funcdcl` | n (0, sum) | When imported functions are implicitly declared: 0=on library load, 1=when one imported function exposes another, 2=like 1 + report |

## Prompt options

Interactive-mode prompt strings, rarely changed: `cmdprompt1`/`cmdprompt2`
(`"%s ampl: "`/`"%s ampl? "`), `dataprompt1`/`dataprompt2` (`"ampl data: "`/`"ampl data? "`),
`prompt1`/`prompt2` (`"ampl: "`/`"ampl? "`), `insertprompt` (`"<%d>"`).

## Miscellaneous options

| Option | Type (default) | Effect |
|---|---|---|
| `convert_logical_to_algebraic` | b (1) | Auto-convert a parenthesized logical-looking constraint to algebraic when possible |
| `integer_markers` | b (1) | Emit MPS `MARKER INTORG`/`INTEND` lines around integer variables (0 = write continuous relaxation instead) |
| `lazy` | b (0) | Treat `=`/`:=` in a `param` statement like `default` (compute lazily) |
| `mpsfile_numwidth` | n (12) | Numeric field width in MPS files written by `write m` |
| `outarg_warn` | b (1) | Warn about unexpected output-argument behavior in imported functions |
| `randparam_warn` | b (1) | Warn when a `param` statement specifies `random` |
| `randseed` | n (1) | Seed for AMPL's RNG; 0 = seed from system clock and report the chosen seed. Re-issuing the option (even to the same value) restarts the sequence |
| `table_errbreak` | n (0, sum) | `read table`/`write table` error handling: 1=suppress write-table errors, 2=suppress read-table errors, 4=report all iteration errors before terminating (when iterating over a set) |
| `table_debug`, `table_debug_template` | n/s | Debugging aid for AMPL text-format database tables — see `https://www.netlib.org/ampl/fixlog` |
| `version` | s | Build/platform/license string reported at AMPL startup |

## See also

- Solver-specific tuning options (a different mechanism — strings passed via
  `(solver)_options`): `../solver-options/`
- `presolve`/`solve_result`/suffix mechanics in narrative form:
  `11-solver-interaction-and-suffixes.md`
- `display`/`print`/`printf` command syntax: `09-display-and-output-commands.md`
- `.dat`/`.mod`/scripting commands these options interact with:
  `06-data-files-and-formats.md`, `10-scripting-and-control-flow.md`
