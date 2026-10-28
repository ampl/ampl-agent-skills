# MP Library Reference Models

Derived from: mp-reference-models.md

Source: `raw/mp-reference-models.md` (`https://mp.ampl.com/models.html`), current as of
2026-10-28. Four small, complete models used as worked examples throughout
`../mp-library/` and `../solver-options/` (e.g. to demonstrate `sol:stub`, `alg:sens`,
`alg:kappa`, `alg:feasrelax`, warm starts, and IIS finding) — kept here as a standalone,
runnable set rather than repeated inline in every file that references them.

## Multi-objective diet model

Two blended/hierarchical objectives (`total_cost` per store, `total_number`) over the
classic AMPL-book diet problem shape (`FOOD`, nutrients split into `MINREQ`/`MAXREQ`,
multiple `STORE`s with different prices). Used to demonstrate `obj:multi`, `.objweight`,
`.objpriority`, sensitivity suffixes, and basis I/O in `../mp-library/` and
`../solver-options/`.

```ampl
set MINREQ;   # nutrients with minimum requirements
set MAXREQ;   # nutrients with maximum requirements
set NUTR := MINREQ union MAXREQ;
set FOOD;
set STORE;

param cost {STORE,FOOD} > 0;
param f_min {FOOD} >= 0;
param f_max {j in FOOD} >= f_min[j];
param n_min {MINREQ} >= 0;
param n_max {MAXREQ} >= 0;
param amt {NUTR,FOOD} >= 0;

var Buy {j in FOOD} >= f_min[j], <= f_max[j];

minimize total_cost {s in STORE}:
   sum {j in FOOD} cost[s,j] * Buy[j];
minimize total_number:  sum {j in FOOD} Buy[j];

subject to diet_min {i in MINREQ}:
   sum {j in FOOD} amt[i,j] * Buy[j] >= n_min[i];
subject to diet_max {i in MAXREQ}:
   sum {j in FOOD} amt[i,j] * Buy[j] <= n_max[i];
```

Data (`FOOD` = BEEF/CHK/FISH/HAM/MCH/MTL/SPG/TUR; `STORE` = "A&P"/JEWEL/VONS; nutrients
A/C/B1/B2/NA/CAL): full `.dat` listing in `raw/mp-reference-models.md`.

## An infeasible model

Small linear model used to demonstrate the Irreducible Inconsistent Subset (IIS) finder
(`alg:iisfind`, see `../mp-library/feature-and-solver-options-guide.md`) and
unbounded-ray suffixes (`alg:rays`). Constraints `c1`–`c3` are incompatible; `c4` is not
needed for the infeasibility, so it is not in the IIS.

```ampl
var x >= 0;
var y >= 0;
var z >= 0;

subj to c1:
   x + y >= 3;
subj to c2:
   x + z <= 1;
subj to c3:
   y + z <= 1;
subj to c4:            # not needed for the infeasibility
   x + y + z <= 10;
```

## Another infeasible model

A small integer-infeasible model used to demonstrate feasibility relaxation
(`alg:feasrelax`, see `../mp-library/feature-and-solver-options-guide.md` and
`../solver-options/`) — solving it with different penalty weights on `C1`/`C2`/`C3`
produces different relaxed solutions.

```ampl
var x integer >= 5;
var y integer;

minimize TotalSum:
    x - 2*y;
subj to C1:
       -x + 21*y >=  2;
subj to C2:
     -3*x +  2*y <=  1;
subj to C3:
     20*x +    y <= 20;
```

## n-Queens model

Binary-formulation n-Queens, used throughout `../mp-library/` and `../solver-options/`
to demonstrate multiple-solution enumeration (`sol:stub`), timing suffixes
(`tech:reporttimes`), warm starts (`alg:start`), and MIP-gap reporting
(`mip:return_gap`, `mip:bestbound`) — its default size (`n=10`) solves fast enough to
iterate on, and `n` can be bumped up to make solve time and warm-start effects visible.

```ampl
param n default 10;
set ROWS := {1..n};
set COLUMNS := {1..n};

var X{ROWS, COLUMNS} binary;   # X[i,j] = 1 if a queen sits at (i,j)

maximize max_queens: sum {i in ROWS, j in COLUMNS} X[i,j];

subject to column_attacks {j in COLUMNS}:
	sum {i in ROWS} X[i,j] = 1;
subject to row_attacks {i in ROWS}:
	sum {j in COLUMNS} X[i,j] = 1;
subject to diagonal1_attacks {k in 2..2*n}:
	sum {i in ROWS, j in COLUMNS: i+j=k} X[i,j] <= 1;
subject to diagonal2_attacks {k in -(n-1)..(n-1)}:
	sum {i in ROWS, j in COLUMNS: i-j=k} X[i,j] <= 1;
```

## See also

- `../mp-library/` — the MP solver-interface layer these models are used to demonstrate
- `../solver-options/` — per-solver tuning options exercised against these models
- `model-library-netlib.md` — a larger, older public model archive for further examples
