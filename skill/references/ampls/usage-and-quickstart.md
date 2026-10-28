# ampls: Installation and the Three Usage Levels in Code

Derived from: ampls-quickstart.md, ampls-usage.md, release-ampls-changelog.md

Source: `ampls-quickstart.md`, `ampls-usage.md`.

## Installation

```bash
pip install amplpy amplpy-cplex      # or:
pip install amplpy amplpy-gurobi     # or amplpy-<solver> for another supported solver
```

Each solver's `ampls` bindings are their own pip package (`amplpy-gurobi`,
`amplpy-cplex`, `amplpy-copt`, `amplpy-xpress`, ...); install only the ones you actually
need, alongside the base `amplpy` package. To run the bundled example scripts: `cd
python/examples`, `pip install -r requirements.txt`, then run the example directly.

## The three usage levels, in code

All three levels start identically — obtain a solver-loaded model instance — and differ
only in how you subsequently read/manipulate it. C++ syntax shown here (see
`api-reference-classes.md` / `callbacks-and-examples.md` for the equivalent Python via
`amplpy.AMPL.to_ampls(...)`):

```cpp
ampls::GurobiDrv drv = ampls::GurobiDrv();
ampls::GurobiModel model = drv.loadModel("diet.nl");
model.optimize();
```

### Generic: works unchanged across every solver

```cpp
double obj = model.getObj();
```

Uses only `ampls::AMPLModel::getObj()` — defined on the shared base class, so identical
code runs against a `GurobiModel`, `CPLEXModel`, or any other solver's model object. This
is the right default whenever the task doesn't inherently require solver-specific
information.

### Solver-specific: relies on one solver's extended interface

```cpp
double obj = model.getDoubleAttr(GRB_DBL_ATTR_OBJVAL);   // ampls::GurobiModel-only method
```

`getDoubleAttr` exists only on `GurobiModel`; the same logic on CPLEX would need a
different method name (see `api-reference-classes.md`). Choose this level when you want
access to a solver's fuller attribute surface (as wrapped by `ampls`) but don't need to
drop all the way to the solver's own C library.

### Solver-native: raw pointer, solver's own C library

```cpp
GRBmodel* grbm = model.getGRBmodel();
double obj;
int status = GRBgetdblattr(grbm, name, &obj);
```

or, for CPLEX:

```cpp
double obj;
int status = CPXgetobjval(model.getCPXENV(), model.getCPXLP(), &obj);
```

The last resort/most powerful option: get the actual native model/environment pointer and
call the solver vendor's own C API directly, exactly as if `ampls` weren't in the picture
at all. Reach for this only when a capability isn't exposed by either of the two levels
above — most everyday tasks (reading solution values, setting common parameters, basic
callbacks) don't need it.

## Version notes (release changelog)

- **0.2.3 (2026-04-08), breaking:** the method injected into `amplpy.AMPL` was renamed
  `import_solution` → `import_ampls_solution`. Older examples (including part of the
  callbacks example page) still show `import_solution`; use the new name.
- **0.2.4 (2026-05-26):** PyInstaller support, updated packages and solver libraries for
  all distributed solvers, Python versions above 3.12 supported.
- Earlier: 0.2.2 updated Gurobi to 12.0; 0.2.1 added the optional `local` argument to
  CPLEX `addLazy`/`addCut` (locally vs. globally valid, default global); 0.2.0 added
  `Constraint.to_string` and `AMPLModel.add_constraint` in Python.

## See also

- Conceptual overview of why these three levels exist and how the class hierarchy behind
  them is structured: `overview-and-architecture.md`
- Full method listing per class (`AMPLModel`, `GurobiModel`, `CPLEXModel`, `GenericCallback`):
  `api-reference-classes.md`
- Complete Python scripts exercising all three levels, plus callbacks: `callbacks-and-examples.md`
