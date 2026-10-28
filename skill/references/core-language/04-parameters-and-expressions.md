# Parameters and Expressions

Derived from: ampl-book.md (ch. 7), release-ampl-changelog.md

Source: *AMPL: A Modeling Language for Mathematical Programming*, 2nd ed., Chapter 7.

## Parameter declarations

```ampl
param T;                                  # scalar
param avail {1..T};                       # indexed -- one value per member of the index set
param demand {DEST,PROD};                 # indexed over pairs -> two subscripts: demand[j,p]
```

An indexed parameter behaves like a vector/array; if the index set is a subset of pairs
(`LINKS within {ORIG,DEST}`), the parameter is effectively a sparse matrix — `cost[i,j]` exists
only where `(i,j) in LINKS`.

## Arithmetic expressions

Standard operators `+ - * / ^` (also `**` for exponentiation), plus `div` (truncated quotient),
`mod` (remainder), and `less` (`a less b` = `max(a-b, 0)`). Precedence, highest to lowest:
`^`/`**` (right-assoc) > unary `+ -` > `* / div mod` > `sum prod min max` (iterated) > `+ - less`
> comparisons/`in` > `not` > `and` > `or` > `if-then-else` (right-assoc). Full table:
`12-syntax-quick-reference.md`.

Built-in functions: `abs acos acosh asin asinh atan atan2 atanh cos cosh exp log log10 max min
sin sinh sqrt tan tanh`, plus set functions `card`, `ord`. `min`/`max` names cannot be
redefined; most other function names can be reused as parameter/variable names, but doing so
makes the original function inaccessible.

**Iterated operators** generalize Σ/Π: `sum`, `prod`, `min`, `max` followed by an indexing
expression:

```ampl
sum {i in ORIG} supply[i]
sum {i in ORIG, j in DEST} cost[i,j] * Trans[i,j]     # sum binds tighter than + -, looser than *
max {i in ORIG} supply[i]
```

Watch precedence when a sum contains a `-`: `sum {p in PROD, t in 1..T} (sum {a in AREA[p]}
revenue[p,a,t]*Sell[p,a,t] - prodcost[p]*Make[p,t] - invcost[p]*Inv[p,t])` needs the outer
parentheses, or the subtraction terms fall outside the sum.

## Logical and conditional expressions

Comparisons `= <> < <= > >=` (alt: `== !=`) return true/false. Combine with `and` (`&&`),
`or` (`||`), `not` (`!`); iterated forms `exists {...} ...` (iterated or) and `forall {...} ...`
(iterated and). An exclusive-or operator `xor` also exists: it was experimental and
became an official feature in AMPL 20250401 (`release-ampl-changelog.md`; the book
predates it):

```ampl
exists {i in ORIG} demand[i] > 10       # true if any origin has demand > 10
forall {i in ORIG} demand[i] > 10       # true if every origin does
```

**Conditional (`if-then-else`) as an expression** — not a statement, a value:

```ampl
if t = first(WEEKS) then inv0[p] else Inv[p,prev(t)]
```

`else 0` may be dropped. Because `then`/`else` bind more loosely than anything else, wrap the
whole conditional in parentheses unless it's the last thing in the statement:

```ampl
subject to Balance {p in PROD, t in WEEKS}:
   Make[p,t] + (if t = first(WEEKS) then inv0[p] else Inv[p,prev(t)])
      = Sell[p,t] + Inv[p,t];
```

This is the idiomatic way to merge two near-duplicate constraint families (a "first period"
special case and a "general period" case) into one declaration.

A numeric value used where a logical one is required is truthy/falsy (0 = false, nonzero =
true) — `if promote[p,t] then ...` works, but be careful: `if t then 0 else ...` is legal and
means something different from `if t = 1 then 0 else ...`. Prefer the explicit comparison.

## Restrictions on parameters (validate at load time)

A restriction phrase (`integer`, `binary`, or a comparison + expression) rejects bad data before
it ever reaches a solver:

```ampl
param T > 1 integer;
param f_max {j in FOOD} >= f_min[j];      # per-member restriction referencing a dummy index
```

Multiple restriction phrases may be comma-separated. A restriction may even reference the
parameter's own earlier-indexed values (careful with the first index — needs an `if`):

```ampl
param cumulative_market {p in PROD, t in 1..T}
   >= if t > 1 then cumulative_market[p,t-1];   # "else 0" implied
```

For restrictions that don't fit inside one declaration (cross-parameter, cross-set
consistency), use a standalone `check` statement — this is the workhorse for catching data
mistakes early:

```ampl
check: sum {i in ORIG} supply[i] = sum {j in DEST} demand[j];
check {p in PROD}: sum {i in ORIG} supply[i,p] = sum {j in DEST} demand[j,p];   # indexed check
```

If a check fails, AMPL prints an error and rejects the whole data load. **Always add checks
liberally** — an uncaught bad data value either crashes model generation with an unhelpful
error, or — worse — silently produces a "solved" LP that's simply wrong.

## Computed parameters (`=`) vs. defaulted parameters (`default`)

```ampl
param tot_sh = sum {j in DEST} share[j];              # ALWAYS this formula; can't also give data for it
param mininv {p in PROD, t in 0..T}
   default frac * market[p,t+1];                      # initial value, but data/assignment can override
```

- `=` makes the parameter fully derived — supplying data for it directly is an error
  (`"mininv was defined in the model"`). AMPL keeps `=`-defined parameters live: if an input
  they depend on changes, the computed value updates automatically for the rest of the session.
- `default` only supplies a fallback, evaluated lazily (first time the parameter's value is
  actually needed, e.g. at `solve`); a `.dat` entry or a `let` assignment later overrides it.
  This is the pattern to use when you want most values auto-computed but a handful of
  data-driven exceptions.
- **Recursive definitions are allowed** (a parameter's formula referencing its own earlier-index
  values, e.g. a running average or a factorial/Fibonacci-style recurrence) as long as there's
  no circular dependency — AMPL detects and errors on genuine cycles.
- Combine `=`/`default` with a restriction for a "computed-and-validated" parameter in one
  declaration: `param mininv {...} = frac * market[p,t+1], >= 0;`

## Randomly generated parameters

Random parameters are computed parameters whose formula calls a built-in random function
(`Normal`, `Uniform`, etc. — full list in the syntax quick reference):

```ampl
param avail_mean > 0;
param avail_variance > 0, < avail_mean / 2;
param avail = max(Normal(avail_mean, avail_variance), 0);   # clamp to avoid a rare negative draw
```

Random streams are deterministic by default (same sequence every `reset`/restart) unless you
set `option randseed n;` — `n = 0` seeds from the system clock for a different sequence each
time; nonzero `n` gives a reproducible sequence. `reset data` on a randomly-computed parameter
draws a fresh sample.

## Logical (binary) parameters

No true boolean type; use `binary` restriction and treat 0/1 as false/true:

```ampl
param promote {PROD,1..T+1} binary;
param mininv {p in PROD, t in 0..T} =
   (if promote[p,t] then fr_pro else fr_reg) * market[p,t+1];
```

## Symbolic (string-valued) parameters

`symbolic` lets a parameter hold a string (or number-as-string) rather than a pure numeric
value; string values can't participate in arithmetic. Two common uses:

```ampl
# 1. Designate specific set members for special roles
param entr symbolic in INTER;
param exit symbolic in INTER, <> entr;

# 2. Attach a documentary label to a set member (plays no role in the optimization)
param orig_name {ORIG} symbolic;
```

String operators/functions (concatenation, substring, regex, etc.) exist but are used mostly in
scripts, not models — see `10-scripting-and-control-flow.md`.

## See also

- Sets and indexing expressions: `03-sets-and-indexing.md`
- How parameter data is actually laid out in files: `06-data-files-and-formats.md`
- The `let` command for changing a parameter's value interactively: `08-commands-modifying-models-and-data.md`
- Full operator precedence table and reserved words: `12-syntax-quick-reference.md`
