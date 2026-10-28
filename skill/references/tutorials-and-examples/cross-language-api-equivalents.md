# Cross-Language API Equivalents

Derived from: basic-commands.md, basic-scripting.md, modeling-and-data.md, ampl-apis.md

Source: `basic-commands.md`, `basic-scripting.md`, `modeling-and-data.md` (syntax
tables embedded in AMPL's official tutorial series, covering AMPL-interactive, Python,
R, MATLAB, C++, C#, and Java).

## Purpose

The core AMPL API (read a model, set an option, solve, retrieve data) is deliberately
near-identical across every language AMPL supports — this file is a quick lookup table
for translating between them, useful when porting a script from one language to another
or when reading example code in an unfamiliar target language. Method names differ mainly
in casing convention (each language's own idiom), not in concept or argument order.

**Caveat on source reliability**: the source for this table was an export
that flattened originally-tabbed, per-language code panels into a single run of text; the
language attribution for a few ambiguous lines (marked below) had to be inferred
heuristically rather than read directly off an explicit label. Treat the "ambiguous"
rows as probably-correct but worth a quick sanity check against current amplpy/rAMPL/etc.
docs before relying on them verbatim.

## Core operations, by language

| Operation | AMPL interactive | Python (amplpy) | R (rAMPL) | C# | Java |
|---|---|---|---|---|---|
| Load a model | `model lemonade.mod;` | `ampl.read("lemonade.mod")` | `ampl$read("lemonade.mod")` | `ampl.Read("lemonade.mod");` | `ampl.read("lemonade.mod");` |
| Set an option | `option solver highs;` | `ampl.set_option("solver", "highs")` | `ampl$setOption("solver", "highs")` | `ampl.SetOption("solver", "highs");` | `ampl.setOption("solver", "highs");` |
| Solve | `solve;` | `ampl.solve()` | `ampl$solve()` | `ampl.Solve();` | `ampl.solve();` |
| Run arbitrary AMPL statements | (native) | `ampl.eval("model;")` / `ampl.eval("data;")` | `ampl$eval("model;")` | `ampl.Eval("model;");` | `ampl.eval("model;");` |
| Reset session | `reset;` | `ampl.reset()` or `ampl.eval("reset;")` | `ampl$reset()` or `ampl$eval("reset;")` | `ampl.Reset();` | `ampl.reset();` |
| Terminate session | `quit;` / `q;` | (invalidates the object — avoid sending `quit`/`exit` via API; let the API's own cleanup handle it) | same caveat | same caveat | same caveat |

Note the Python method-naming convention: `snake_case` (`set_option`, `read_data`) in
current `amplpy`; some older example code in the wild uses `camelCase` (`setOption`,
`readData`) — both may work depending on the installed `amplpy` version, but prefer
`snake_case` for new code (matches `../amplpy/api-reference-classes.md`).

**Important — terminating commands and the API**: sending `quit;`/`exit;`/`q;` through an
API's `eval()` invalidates the underlying AMPL object, after which it can't accept further
input. The API's own object-lifecycle cleanup (e.g. Python's garbage collection of the
`AMPL` instance, or an explicit `.close()`) already handles session teardown correctly —
don't send terminating commands proactively from API code.

**Reloading model/data via the API**: whenever replacing a previously-loaded model or
data file through the API (as opposed to a fresh interactive session), explicitly call one
of AMPL's `reset` forms first (`../core-language/08-commands-modifying-models-and-data.md`)
— the API does not do this automatically, and skipping it leaves stale declarations/data
behind exactly as it would in an interactive session.

## Retrieving data as a native structure

| Language | Pattern |
|---|---|
| Python | `df = ampl.get_data("lemonade, iced_tea, profit"); df.to_pandas()` |
| R | `df <- ampl$getData("lemonade, iced_tea, profit")` — already an R `data.frame`, no conversion step needed (rAMPL is built on Rcpp) |
| C++ | `ampl::DataFrame df = ampl.getData("lemonade, iced_tea, profit");` — no built-in conversion to a "native" tabular type; write your own transpose/conversion helper if needed (see the worked `transpose1D` example in the tutorial source) |

The recommended general pattern across every language: use the API purely to get/set
data, then do all data manipulation in the host language's own native structures (pandas
in Python, `data.frame` in R) rather than working with the API's own DataFrame-like
intermediate type any longer than necessary — the intermediate type exists to bridge to
AMPL efficiently, not to be a general-purpose data-manipulation tool in its own right.

## Indexed-entity access pattern (illustrative, Python-centric with notes for others)

```python
# Python: iterate over a (possibly indexed) variable's instances
vars = ampl.get_variables()          # -> EntityMap: (name, Variable) pairs
for name, var in vars:
    for index, instance in var:      # instance is a Variable-instance-like object
        val = instance.value()
        if val != round(val):
            instance.set_value(round(val))
```

```r
# R: analogous pattern, via data.frame
vars <- ampl$getVariables()
for (var in vars) {
  value_df <- var$getValues()
  # ... modify value_df's value column ...
  var$setValues(value_df)
}
```

The shapes differ (Python: nested iteration over entity → instance; R: a `data.frame`
per entity, modify-then-write-back) but the underlying operation — read all instance
values, transform, write back — is the same across languages. Full method reference for
the Python side: `../amplpy/api-reference-classes.md`.

## Installing each API, and where its documentation is

From the AMPL APIs page (`ampl-apis.md`):

| Language | Install | Documentation |
|---|---|---|
| Python (`amplpy`) | `python -m pip install amplpy` | https://amplpy.ampl.com/ |
| R (`rAMPL`) | `install.packages("Rcpp", type="source")`, then `install.packages("https://ampl.com/dl/API/rAMPL.tar.gz", repos=NULL)` | https://rAMPL.ampl.com/ |
| C#, C++, C, Java, MATLAB | one API bundle per platform from the AMPL Portal: `https://portal.ampl.com/dl/modules/amplapi-module.<platform>.<ext>` (`mswin64.zip`, `linux64.tgz`, `macos64.tgz`) | https://ampl.com/api/latest/dotnet/, `/cpp/`, `/c/`, `/java/`, `/matlab/` |
| Solver callbacks (`ampls`) | see `../ampls/usage-and-quickstart.md` | https://ampls.ampl.com/, GitHub `ampl/ampls-api` |

The C API is listed alongside the others but has no column in the tables above (the
tutorial sources show no C examples).

## See also

- The worked tutorial these tables were extracted from, with full narrative context:
  `worked-example-tutorial.md`
- Full amplpy method reference (Python specifically): `../amplpy/api-reference-classes.md`,
  `../amplpy/core-workflow-best-practices.md`
- AMPL's own native `reset`/`model`/`data` command semantics, underlying every language's
  API wrapper: `../core-language/08-commands-modifying-models-and-data.md`
