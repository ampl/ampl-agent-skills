# ampls Callbacks: Worked Patterns

Derived from: ampls-example-callbacks-first.md, solver-callbacks-webinar-transcript.md

Source: `ampls-example-callbacks-first.md` (bundled example scripts), `solver-callbacks-webinar-transcript.md`
(AMPL Optimization webinar; ASR transcript — see note below).

> **Source-quality note**: the webinar transcript source is raw, unedited automatic
> speech recognition with no punctuation and known misheard terms (e.g. "ample" →
> AMPL, "calex"/"CeX" → CPLEX, "gur"/"Gabi" → Gurobi, "MTC" → MTZ). The narrative content
> below has been reconstructed from that transcript and cross-checked against the
> accompanying example scripts, but if a specific claim here matters for a decision,
> verify against the actual video (AMPL Optimization YouTube channel) or current
> `amplpy`/`ampls` docs (amplpy.ampl.com, ampls.ampl.com) rather than treating this file's
> wording as a precise quote.

## Table of contents

- The load → export → callback → optimize → import round trip (canonical pattern)
- Generic callback structure: recording stages, conditional logic per `CBWhere`
- Stopping the solve early: MIP-gap and no-improvement-timeout criteria
- Lazy constraints for combinatorial subtour elimination (TSP)
- User cuts via max-flow/min-cut separation (TSP, alternate formulation)
- Multi-model workflows and native C API access
- Column generation with a callback-adjusted stopping rule (cutting stock)
- Why generic callbacks matter: solver portability

## The canonical round trip

Every example in this source follows the same shape: build/load a model in `amplpy`,
export it to `ampls` for the chosen solver, attach a callback if needed, optimize, then
import the solution back into the `amplpy` session for post-processing:

```python
ampl = AMPL()
try:
    ampl.read("models/queens.mod")
    ampl.param["size"] = 10

    model = ampl.to_ampls(SOLVER)          # export: amplpy -> ampls
    cb = Callback()
    model.set_callback(cb)
    model.optimize()

    ampl.import_ampls_solution(model)      # import: ampls -> amplpy
    assert model.get_obj() == ampl.get_current_objective().value()
finally:
    ampl.close()
```

The `assert` at the end — checking that `ampls`'s and `amplpy`'s view of the objective
agree after import — is a useful sanity check to keep in any script doing this round
trip, since it's cheap and would catch an import step that silently failed or was skipped.

## Generic callback structure

A `GenericCallback` subclass's `run()` method is called repeatedly during the solve; the
standard pattern is to switch on `self.get_ampl_where()` (see `CBWhere` values in
`api-reference-classes.md`) and act only on the stages that matter for the task at hand,
returning `0` to let the solve continue:

```python
class Callback(ampls.GenericCallback):
    def __init__(self):
        self.calls = {w: 0 for w in ampls.Where}
        self.last_bound = 10e10

    def run(self):
        t = self.get_ampl_where()
        self.calls[t] += 1
        if t in (ampls.Where.MIPNODE, ampls.Where.MIPSOL):
            obj_bound = self.get_value(ampls.Value.MIP_OBJBOUND)
            if self.last_bound == obj_bound:
                return 0                       # skip if bound hasn't actually improved
            self.last_bound = obj_bound
            gap = self.get_value(ampls.Value.MIP_RELATIVEGAP)
            print(f"nonzeros={sum(x!=0 for x in self.get_solution_vector())} "
                  f"obj={self.get_obj()} bound={obj_bound} gap={gap}")
        if t == ampls.Where.NOTMAPPED:
            pass  # record solver-specific stage name via get_where_string() if needed
        return 0
```

**Gate on "has this actually changed" before printing/acting**, not just "have we reached
this stage" — `MIPNODE`/`MIPSOL` callbacks fire very frequently; without the
`last_bound`-comparison guard shown above, output floods with redundant lines even when
nothing meaningful has happened. This pattern (cache the last-seen value of whatever
you're tracking, compare before acting) recurs across every example in this source and is
worth treating as the default, not an optimization to add later.

`CanDo` checks (e.g. `self.can_do(ampls.CanDo.GET_MIP_SOLUTION)`) let a callback probe,
at points where the exact solver-native stage isn't one of the standard mapped `CBWhere`
values, whether a particular action is currently valid before attempting it — relevant
mainly for advanced/defensive callback code that needs to behave correctly across solvers
with slightly different internal stage granularity.

## Stopping the solve early

Returning `-1` from `run()` interrupts the solve — the mechanism behind every
early-termination pattern. Two common criteria, both checked inside `MIPSOL`/`MIPNODE`:

**MIP-gap threshold**:
```python
def _evaluate_mipgap(self, mipsol: bool):
    gap = self.get_value(ampls.Value.MIP_RELATIVEGAP)
    if gap < DESIREDGAP:
        return -1          # stop: good enough
    return 0
```

**No-improvement timeout** (stop if the objective hasn't moved in `MAX_TIME` seconds):
```python
def _evaluate_solutionprogress(self):
    obj = self.get_obj()
    if obj != self.last_obj:
        self.last_obj_time = time.time()
        self.last_obj = obj
    elif time.time() - self.last_obj_time > MAX_TIME:
        return -1
    return 0
```

Both are legitimate, common ways to trade proven optimality for wall-clock time — see the
equivalent solver-option-only approach (no callback needed) for a plain gap/time limit in
`../core-language/11-solver-interaction-and-suffixes.md`. **Reach for a callback-based
stopping rule specifically when the criterion is dynamic** (e.g. "increase the acceptable
gap over time," shown in "Column generation" below) rather than a single fixed
gap/time value a plain solver option could express directly.

**Retrieving the MIP gap back in AMPL** after the solve requires explicitly requesting it
at export time (`return_mipgap` is not sent by default) — otherwise
`ampl.get_value("Initial.relmipgap")` will not reflect the solve:
```python
model = ampl.to_ampls(SOLVER, ["return_mipgap=5"])
# or when exporting directly (see the pattern-generation example below):
# ampl.to_ampls(SOLVER, ["return_mipgap=5"])
```

## Lazy constraints: subtour elimination for TSP

Two structurally different ways to prevent a TSP formulation's LP relaxation from
returning disconnected sub-tours instead of one full tour: build the exclusion into the
model upfront (MTZ constraints), or exclude sub-tours reactively via a callback as they're
found. The webinar/example material frames these as a genuine trade-off, not "callback is
always better":

- **MTZ (Miller–Tucker–Zemlin) constraints**, added directly in the AMPL model: correct
  and requires no callback, but the extra constraints make the formulation noticeably
  harder to solve at scale — described in the source material as struggling well before
  even moderately large instances (tens to low hundreds of nodes), depending on the
  specific instance.
- **Lazy-constraint subtour elimination**, via callback: leaves the base model small and
  clean; whenever a candidate integer solution (`Where.MIPSOL`) contains more than one
  disjoint tour, add a lazy constraint forbidding that exact combination of sub-tours and
  let the solver continue:

  ```python
  def mipsol(self):
      sol = self.get_solution_vector()
      values = {xvars[i]: sol[i] for i in xvars if abs(sol[i]) > 1e-5}
      uf = UnionFind()
      for (u, v) in values:
          uf.link(u, v)
      groups = uf.groups()
      if len(groups) > 1:
          for grp in groups:
              cutvarnames = [ampls.tuple2var('x', i, j) for i in grp for j in grp if i != j]
              coeffs = [1] * len(cutvarnames)
              self.add_lazy(cutvarnames, coeffs, ampls.CutDirection.LE, len(grp) - 1)
      return 0
  ```

  The cut logic: within any detected sub-tour group of size `k`, the number of *used*
  edges among that group's nodes cannot exceed `k - 1` (a genuine tour touching all `k`
  nodes plus others would use exactly `k` edges within the group only if it were itself a
  closed sub-tour — forbidding `k` or more edges among the group rules out exactly that).

  **`enableLazyConstraints()` must be called once before `optimize()`** whenever a
  callback will call `add_lazy`/`addLazyIndices` — a required setup step, not optional
  boilerplate.

## User cuts via max-flow/min-cut separation

An alternative (undirected-edge) TSP formulation, using `Where.MIPNODE` instead of
`Where.MIPSOL`, separates fractional (not just integer) solutions using a max-flow
computation between node pairs — if the max flow between any two nodes in the current
relaxed solution is less than 1, that reveals a cut violated by the current point, added
as a **user cut** (`add_cut`, not `add_lazy` — user cuts strengthen the relaxation at
fractional points, lazy constraints exclude specific *integer* solutions):

```python
def mipnode(self):
    sol = self.get_solution_vector()
    capacities = {xvars[i]: sol[i] for i in xvars if abs(sol[i]) > 1e-5}
    for i in range(1, len(vertices)):
        max_flow, partition = ford_fulkerson(capacities, vertices[0], vertices[i])
        if max_flow <= 1 - 1e-5:
            p1, p2 = set(partition), set(vertices) - set(partition)
            cutvarnames = [ampls.tuple2var('x', i, j) for i in p1 for j in p2]
            self.add_cut(cutvarnames, [1]*len(cutvarnames), ampls.CutDirection.GE, 1)
            return 0
    return 0
```

Both TSP examples cap or guard the per-callback work (a node-count cutoff in the shown
`mipnode`) — worth doing in any node-callback that runs nontrivial computation
(max-flow, connected-components), since `MIPNODE` can fire far more often than `MIPSOL`
and unbounded per-call work compounds badly across a large branch-and-bound tree.

## Multi-model workflows and native access

`ampls` supports building/solving several independent AMPL models side by side (e.g. to
compare a feasible vs. an intentionally infeasible variant), each exported and solved
independently:

```python
model = ampl.to_ampls(SOLVER)
for opt, val in options.items():
    model.set_option(opt, val)            # AMPL-driver-level options — mostly solver-portable
if SOLVER == "gurobi":
    model.set_param("Threads", 4)         # solver-specific parameter wrapper
if use_native_call:
    if SOLVER == "gurobi":
        ampls.GRBoptimize(model.get_grb_model())      # fully native C call
    else:
        model.optimize()                                # generic ampls call
```

This illustrates the three usage levels from `usage-and-quickstart.md` side by side in one
function: driver-level options work the same regardless of solver, `set_param` needs a
per-solver branch, and the native call needs both a per-solver branch *and* the solver's
own function name. **Diagnosing infeasibility**: setting a solver's IIS-related option
(e.g. `iisfind=1` for Gurobi) plus reading back `_var.iis`/`_con.iis` (the built-in AMPL
IIS suffixes, `../core-language/11-solver-interaction-and-suffixes.md`) via
`ampl.get_data(...)` after import is the standard diagnostic pattern — note that if
presolve is aggressive enough to detect the infeasibility itself, the model may never even
reach the solver (an explanatory exception is raised instead); turning off or lowering
presolve is how the examples force the model through to the solver for IIS analysis.

## Column generation with a callback-adjusted stopping rule

A cutting-stock (pattern generation) column-generation setup — a `Master` AMPL model and
a `Sub` pricing-problem AMPL model, iterating in Python — is a good illustration of mixing
plain AMPL/amplpy scripting with `ampls` only at the very end, for the final
integer-restricted master solve:

```python
while True:
    Master.solve()
    Sub.param["val"].set_values(Master.con["OrderLimits"].get_values())   # duals -> pricing problem
    Sub.solve()
    if Sub.obj["TotVal"].value() <= 1.00001:
        break                                            # no improving pattern found
    Master.param["newPat"].set_values(Sub.var["Qty"].get_values())        # new pattern -> master
    Master.eval("let nPatterns := nPatterns + 1; let {w in WIDTHS} rolls[w, nPatterns] := newPat[w];")

Master.option["relax_integrality"] = 0
ampls_model = Master.to_ampls(SOLVER, ["return_mipgap=5"])
```

The final MIP solve then uses a callback that **increases the acceptable MIP gap over
time**, according to a predefined schedule — a dynamic stopping rule that plain
solver options couldn't express directly, and the concrete case where reaching for a
callback (over a fixed gap/time limit option) earns its complexity:

```python
class MyCallback(ampls.GenericCallback):
    def run(self):
        if self.get_ampl_where() == ampls.Where.MIPNODE:
            runtime = self.get_value(ampls.Value.RUNTIME)
            if runtime >= self._stoprule["time"][self._current]:
                self._continue_opt = True   # signal: stop now, but restart with a looser gap
                return -1
        return 0
```

**Most solvers don't allow changing optimization parameters from inside a running
callback** (Gurobi is called out explicitly) — the workaround shown is to interrupt the
solve entirely (`return -1`), update the parameter (e.g.
`ampls_model.setAMPLParameter(ampls.SolverParams.DBL_MIPGap, new_gap)`) from *outside* the
callback, and re-invoke `optimize()` in a loop until the stopping schedule is exhausted.
This stop/adjust/restart loop is the general pattern whenever a callback needs to change a
solver control mid-run rather than merely read state or add cuts/lazy constraints.

## Why generic callbacks matter: portability

The webinar's framing device is a single TSP callback written once against
`GenericCallback`, then run unmodified against both Gurobi and CPLEX by changing only the
`SOLVER`/import line (`import amplpy_gurobi as ampls` → `import amplpy_cplex as ampls`) —
this is the concrete payoff of "generic usage" from `overview-and-architecture.md`: the
same subtour-elimination logic, cut-adding calls, and stage-detection code work
unchanged across solver backends, with the CPLEX-specific single-thread guard
(`api-reference-classes.md`) as the one notable exception that needs a per-solver branch.

## See also

- Class/method reference for everything used above (`GenericCallback`, `CBWhere`,
  `CutDirection`, `Value`, `SolverParams`): `api-reference-classes.md`
- The three usage levels (generic / solver-specific / solver-native) this file's examples
  exercise: `overview-and-architecture.md`, `usage-and-quickstart.md`
- AMPL-side IIS/suffix mechanics referenced for infeasibility diagnosis:
  `../core-language/11-solver-interaction-and-suffixes.md`
- Column generation's AMPL-native counterpart (no `ampls` involved) — dual values driving
  a pricing subproblem: `../modeling-patterns/columnwise-formulations.md`
