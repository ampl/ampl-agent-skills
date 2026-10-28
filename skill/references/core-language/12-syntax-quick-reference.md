# Syntax Quick Reference (AMPL Reference Manual Digest)

Derived from: ampl-book.md (Appendix A), basic-scripting.md, ampl-suffixes.md

Source: *AMPL: A Modeling Language for Mathematical Programming*, 2nd ed., Appendix A
("AMPL Reference Manual"). This file is a compact lookup companion — the narrative
explanations of most of this material live in the other `core-language/` files (linked
throughout); use this file when you already know the concept and just need the exact
table, precedence, or reserved word.

## Table of contents

- Lexical rules: names, literals, comments, reserved words
- Operator precedence table
- Built-in function tables (arithmetic, random, string/regex)
- Piecewise-linear term syntax
- Suffix tables (variables, constraints, objectives)
- Command list (Table A-9) and generic introspection names (Table A-13)
- `printf` conversion specifiers
- Auxiliary solver files
- Built-in timing parameters
- Command-line invocation notes

## Lexical rules

- Names: Unicode letters/digits/underscore, case-sensitive; cannot look like a numeric
  constant. Words beginning with `_` are reserved for AMPL's own introspection names.
- Numbers: standard scientific notation; `d`/`D`/`e`/`E` all synonymous as exponent markers
  (`1.23D-45`). All arithmetic is double precision.
- Literals: single- or double-quoted; double the delimiter to embed it (`'x''y'` = `x'y`);
  `\` + newline allows embedded newlines. `'abc'` and `"abc"` are identical. A literal and
  the "same" numeric constant are unrelated: `1 <> '1'`.
- Comments: `# to end of line`, or `/* ... */` (no nesting).
- Every statement ends in `;`. Whitespace is insignificant between tokens.

### Reserved words (cannot be redeclared)

```
Current  IN  INOUT  Infinity  Initial  LOCAL  OUT  all  binary  by  check
complements  contains  default  dimen  div  else  environ  exists  forall
if  in  integer  less  logical  max  min  option  setof  solve_exitcode
solve_message  solve_result  solve_result_num  suffix  sum  symbolic  table
then  union  until  while  within
```
Everything else (`prod`, function names, etc.) is *predefined but redefinable* — e.g.
`set prod;` shadows the `prod` reduction operator within that scope; the original meaning
becomes inaccessible once shadowed.

### Preferred / synonym operator spellings (preferred form listed first)

| Preferred | Synonym |
|---|---|
| `^` | `**` |
| `=` | `==` |
| `<>` | `!=` |
| `and` | `&&` |
| `not` | `!` |
| `or` | `\|\|` |
| `prod` | `product` |

## Operator precedence (Table A-1, low → high)

| # | Operator(s) | Type | Notes |
|---|---|---|---|
| 1 | `if-then-else` | A, S | right-associative; missing `else` → `else 0` (arithmetic) or required (set) |
| 2 | `or` `\|\|` | L | |
| 3 | `exists` `forall` | L | logical reduction operators |
| 4 | `and` `&&` | L | |
| 5 | `< <= = == <> != >= >` | L | |
| 6 | `in` `not in`, `within` `not within` | L | set membership / subset |
| 7 | `not` `!` | L | logical negation |
| 8 | `union` `diff` `symdiff` | S | |
| 9 | `inter` | S | |
| 10 | `cross` | S | Cartesian product |
| 11 | `setof` `..` `by` | S | set constructors |
| 12 | `+` `-` `less` | A | `a less b` ≡ `max(a-b, 0)` |
| 13 | `sum` `prod` `min` `max` | A | arithmetic reduction operators |
| 14 | `*` `/` `div` `mod` | A | `div` = truncated integer quotient |
| 15 | `+` `-` (unary) | A | |
| 16 | `^` `**` | A | right-associative |

Type column: **A**rithmetic, **L**ogical, **S**et. All operators except exponentiation and
if-then-else are left-associative. Reduction over an empty set yields the identity: `0` for
`sum`, `1` for `prod`, `Infinity` for `min`, `-Infinity` for `max`; `exists` over empty is
false, `forall` over empty is true.

## Built-in functions

### Arithmetic (Table A-2)

`abs` `acos` `acosh` `alias(v)` `asin` `asinh` `atan` `atan2(y,x)` `atanh` `ceil` `ctime()`
`ctime(t)` `cos` `exp` `floor` `log` `log10` `max(x,y,...)` `min(x,y,...)`
`precision(x,n)` `round(x,n)` `round(x)` `sin` `sinh` `sqrt` `tan` `tanh` `time()`
`trunc(x,n)` `trunc(x)`

`round`/`trunc` with `n`: round/truncate to `n` places past the decimal (negative `n` =
places before the decimal); missing `n` defaults to `0` (ordinary integer rounding).
`precision(x,n)` rounds to `n` *significant* digits instead. `alias(v)` returns a model
entity's alias string.

### Random number generation (Table A-3)

`Beta(a,b)` `Cauchy()` `Exponential()` `Gamma(a)` `Irand224()` `Normal(mu,sigma)`
`Normal01()` `Poisson(mu)` `Uniform(m,n)` `Uniform01()`

Seed with command-line `-sN` or `option randseed`; `option randseed ''` prints and picks an
auto-seed. See `04-parameters-and-expressions.md` for the interaction with `reset data`
(random parameters redraw on `reset data`, but only `reset;` restarts the generator's
sequence).

### Strings and regular expressions (Table A-4)

| Function | Purpose |
|---|---|
| `s & t` | concatenate (precedence *below* all arithmetic operators) |
| `num(s)` | string → number; error if not a valid number after trimming whitespace |
| `num0(s)` | like `num` but never errors — returns 0 if no numeric prefix found |
| `ichar(s)` / `char(n)` | Unicode value of first char / inverse |
| `length(s)` | character count |
| `substr(s,m,n)` | `n`-char substring starting at position `m`; `n` omitted = rest of string |
| `sprintf(fmt, args...)` | like `printf` but returns the string |
| `match(s,re)` | start position of regex `re` in `s`, 0 if absent |
| `sub(s,re,repl)` / `gsub(s,re,repl)` | replace first / all regex matches |

Regex flavor is Unix-like: `.` any char, `[abc]`/`[a-z0-9]` class, `[^...]` negated class,
`r*` `r+` `r?` repetition, `^r`/`r$` anchors, `(...)` grouping, `|` alternation, `\`
escapes a metacharacter. In `sub`/`gsub` replacement text, `&` or `\0` = whole match,
`\1`-`\9` = the *n*th parenthesized group. Full narrative coverage (composite-key
splitting, `&` float-formatting gotcha): `10-scripting-and-control-flow.md`.

## Piecewise-linear terms

```
<< breakpoints ; slopes >> var
<< breakpoints ; slopes >> (cexpr)
<< breakpoints ; slopes >> (var, cexpr)
```

`breakpoints`/`slopes` are comma-separated `cexpr` lists (each optionally indexed, or of
the special form `{if lexpr}` to conditionally omit a term). Slopes count must be
breakpoints count + 1; breakpoints must be non-decreasing. Two-operand form
`f(var) - f(expr)` zeroes the result when `var == expr`. Full worked treatment of
piecewise-linear cost/formulation patterns: `../modeling-patterns/piecewise-linear-programs.md`.

## Suffixes (Tables A-6, A-7, A-8; dev.ampl.com suffix reference)

The narrative version of this material — with worked examples and the ldual/udual sign
rules — lives in `11-solver-interaction-and-suffixes.md`; this is the exhaustive table.

**Variables** (Table A-6): `.astatus` `.init` `.init0` `.lb` `.lb0` `.lb1` `.lb2` `.lrc`
`.lslack` `.rc` `.relax` `.slack` `.sstatus` `.status` `.ub` `.ub0` `.ub1` `.ub2` `.urc`
`.uslack` `.val`

**Constraints** (Table A-7): `.astatus` `.body` `.dinit` `.dinit0` `.dual` `.lb` `.lbs`
`.ldual` `.lslack` `.slack` `.sstatus` `.status` `.ub` `.ubs` `.udual` `.uslack`

**Objectives** (Table A-8): `.val`. The dev.ampl.com suffix reference adds `.astatus`,
`.exitcode`, `.message` and `.result` (exit code, message and result string from the most
recent solve with this objective).

**Problems**: `.astatus`, `.exitcode`, `.message`, `.result` (same, per named problem).

**Also listed on dev.ampl.com** (`ampl-suffixes.md`), not in the book's Tables A-6/A-7:
`.defeqn` on variables (index in `_con` of the "defining constraint" used to substitute the
variable out) and `.dual` on such variables (dual value of that defining constraint);
`.defvar` on constraints (index in `_var` of the defined variable the constraint
substituted out).

**Complementarity constraints** extend this: `.Lsuffix`/`.Rsuffix` address the left/right
sub-constraint's own suffix; the unadorned name's `.slack` becomes a satisfaction measure
(positive = both strict, `0` = exact, negative = violated). See
`../modeling-patterns/complementarity-problems.md`.

Declaring a new suffix: `suffix name [binary|integer|symbolic] [>=expr] [<=expr] [IN|OUT|INOUT|LOCAL];`
— directions are from the *solver's* perspective. Full pattern and CPLEX/sensitivity/IIS
examples: `11-solver-interaction-and-suffixes.md`.

## Commands (Table A-9)

Full alphabetical list AMPL recognizes as a command (as opposed to a model declaration):
`call` `cd` `check` `close` `commands` `data` `delete` `display`(+ `csvdisplay`, `_display`)
`drop` `end` `environ` `exit` `expand` `fix` `include` `let` `load` `model` `objective`
`option` `print` `printf` `problem` `purge` `quit` `read` `read table` `redeclare` `reload`
`remove` `reset` `restore` `shell` `show` `solexpand` `solution` `solve` `update` `unfix`
`unload` `write` `write table` `xref`

Most of these are covered narratively, grouped by purpose, in `08-commands-modifying-models-and-data.md`
(let/fix/drop/reset/delete/purge/redeclare), `09-display-and-output-commands.md`
(display/print/printf/show/xref/expand), `10-scripting-and-control-flow.md`
(for/repeat/if/break/continue — technically statements, not this table), and
`11-solver-interaction-and-suffixes.md` (solve/problem/environ).

### Generic introspection names (Table A-13)

Beyond the `_var`/`_con`/`_obj`/`_PARS`/`_SETS`/... families already covered in
`09-display-and-output-commands.md` and `10-scripting-and-control-flow.md`, AMPL exposes
raw problem-size counters, useful for generic diagnostic scripts or logging:
`_nvars` `_ncons` `_nobjs` `_nccons` (pre-presolve counts and names/synonyms) and their
solver-view (`_s`-prefixed) equivalents `_snvars` `_sncons` ... plus finer breakdowns:
`_snbvars` (binary vars) `_snivars` (general integer vars) `_snlcc`/`_snnlcc` (linear/nonlinear
complementarity constraints) `_snlnc`/`_snnlnc` (linear/nonlinear network constraints)
`_snnlcons` `_snnlobjs` `_snnlv` (nonlinear constraints/objectives/variables)
`_snzcons`/`_snzobjs` (Jacobian/gradient nonzero counts). `option show_stats 1;` prints
most of this automatically after `solve` — reach for the raw parameters only when scripting
a custom size/complexity report.

## `printf` conversion specifiers (Table A-10)

`%d`/`%i` signed decimal · `%u` unsigned decimal · `%o` unsigned octal (no leading `0`) ·
`%x`/`%X` unsigned hex (lower/upper) · `%c` single character · `%s` string ·
`%q` quote string per data-section rules · `%Q` always quote · `%f` fixed decimal ·
`%e`/`%E` exponential · `%g`/`%G` shorter of `%f`/`%e` · `%%` literal `%`.

Modifiers between `%` and the letter: `-` left-justify, `+` force sign, `0` zero-pad,
field width, `.precision` (decimal places for `%f`/`%e`, significant digits for `%g`,
min digits for `%d`, max chars for `%s`). Width/precision can be `*` to pull the next
arglist value. C escapes supported (`\n` `\t` `\a` `\xNN` etc.). Narrative usage and the
"must nest a `for` loop, one `printf` call can't handle a variable column count" gotcha:
`10-scripting-and-control-flow.md`.

Printing-precision options (cosmetic vs. solution-altering — full explanation in
`09-display-and-output-commands.md`): `display_precision` `display_round` `display_eps`
`print_precision` `print_round` `print_separator` `expand_precision` `expand_round`
`objective_precision` `output_precision` `solution_precision` `solution_round`
`csvdisplay_precision` `csvdisplay_round` `display_1col` `display_max_2d_cols`
`display_transpose` `display_width` `gutter_width` `omit_zero_rows` `omit_zero_cols`.

## Auxiliary solver files (Table A-12)

Controlled by `option <solver>_auxfiles` (for `solve`) or `$auxfiles` (for `write`); a
capitalized key letter means "only if the problem is nonlinear."

| Key | File | Contents |
|---|---|---|
| `a` | `stub.adj` | constant added to objective values |
| `c` | `stub.col` | AMPL names of variables the solver sees |
| `e` | `stub.env` | environment (written by `solve`) |
| `f` | `stub.fix` | variables eliminated because their values are known |
| `p` | `stub.spc` | MINOS "specs" file (output style `m`) |
| `r` | `stub.row` | AMPL names of constraints/objectives the solver sees |
| `s` | `stub.slc` | constraints eliminated from the problem |
| `u` | `stub.unv` | unused variables |

## Built-in timing parameters (Table A-14)

`_ampl_elapsed_time` / `_system_time` / `_user_time` / `_time` (sum) — AMPL process itself.
Same four suffixes (`_elapsed_time`/`_system_time`/`_user_time`/`_time`) also exist for
`_shell_*`, `_solve_*` (most recent shell/solve command) and `_total_shell_*`/`_total_solve_*`
(cumulative across the session). `option times 1;` / `option gentimes 1;` print AMPL-side
timing automatically after each solve.

## Command-line invocation

`ampl [options] [file [file...]]` — no file argument (or a bare `-`) means read from
standard input. `ampl '-?'` prints this table at the terminal.

| Flag | Effect | Equivalent `option` setting |
|---|---|---|
| `-Cn` | `0` suppress Cautions, `1` default, `2` treat as error | `option Cautions n;` |
| `-Ln` | `0` = treat linear definitional constraints and `var =` declarations as nonlinear | `option linelim n;` |
| `-P` | skip presolve | `option presolve 0;` |
| `-S` | substitute out definitional constraints (`var = expression`) | `option substout 1;` |
| `-T` | print a detailed summary of genmod-phase resource use (time/memory per entity) after each `solve` | `option gentimes 1;` |
| `-enn` | exit (`nn>0`) or abort command (`nn<0`) at the *nn*-th error; `0` = never exit | `option eexit nn;` |
| `-g` | run in a separate process group | — |
| `-ix` | import functions from `x` (`-i?` for details) | — |
| `-ooutopt` | see `-o?` for details | `option outopt fstub;` (with `-ofstub`) |
| `-s[seed]` | seed for random numbers; bare `-s` = current time | `option randseed ...;` |
| `-t` | show elapsed/CPU times | `option times 1;` |
| `-v` | show version and license details (`-v?` for other `-v` options) | `option version;` |
| `--version` | show version and exit, ignoring license files | — |
| `-xnn` | allow `nn` wall-clock seconds of execution time | — |
| `-??` | show debug and obscure options | — |

`-T`/`gentimes` is the one worth calling out specifically: it's the standard way to see
where AMPL itself (as opposed to the solver) is spending time/memory generating a model
instance — useful when a large model is slow to *build*, not just slow to *solve*. Same
effect from an API: `ampl.set_option("gentimes", 1)` (or the language's equivalent —
`../tutorials-and-examples/cross-language-api-equivalents.md`).

- `-sN` sets the random seed (`option randseed`); no `-s` = same as `-s1`.
- `-v` / `option version` prints the AMPL build version.
- `-R` (first argument only): restricted "server mode" — disables `cd`/`shell`, locks
  `TMPDIR`/`ampl_include`/`PATH`, disallows pipe functions, restricts solver/redirection
  names to alphanumeric (so output can't escape the current directory). Useful when
  embedding AMPL in a service that runs untrusted model files.
- `-ilibs`: initial imported-function/table-handler libraries to load (defaults to
  `-i$AMPLFUNC`; falls back to `amplfunc.dll` in the current directory if present).
- `OPTIONS_IN` / `OPTIONS_INOUT` / `OPTIONS_OUT`: inherited environment variables naming
  files of `option` commands to read at startup / read-then-write-at-exit / write-at-exit —
  the mechanism for persisting option settings across sessions.
- The literal filename `-` (a lone minus sign) is standard input — useful for loading a
  file, then continuing interactively: `ampl mulled_wine.mod -` loads the model, then
  drops into the normal `ampl:` prompt for `option solver ...;`/`solve;`.

## See also

- Style conventions and idiom preferences (separate from raw syntax): `02-style-and-best-practices.md`
- Every other `core-language/` file cross-references back here for exhaustive tables;
  this file is deliberately dense and non-narrative — read the linked files first if a
  term here is unfamiliar.
