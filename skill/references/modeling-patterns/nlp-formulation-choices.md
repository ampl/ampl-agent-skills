# Nonlinear Formulation Choices: Substitute or Name, Coordinates, Redundant Convex Rows

Derived from: mp-choosing-between-formulations.md ("Nonlinear models: substitute or
name"), mp-expressions-supported.md ("Redundant convex constraints on lifted variables",
general nonlinear functions); plus developer field measurements (benchmark studies of
nonconvex MINLP formulations, and an NLP-based heuristic for a power-system control
problem), with the published literature cited inline. The substitution figures (25 %,
1.7×) and the AC-OPF cone result are also in the MP guide; the other "measured" figures
in this file (starting points, disaggregation, smoothing, the reliability model) are
field measurements only.

`nonlinear-programs.md` covers the language mechanics: initial values, `substout`,
defined variables, and smooth expressions. This file covers the choices those mechanics
leave open, which decide whether a nonlinear model solves well. None has a universal
answer. Each section says what was measured and how to decide on your own model.
"Measured" numbers illustrate direction and size, not a guarantee for your solver version.

## Table of contents

- Terminology used here
- Substitute an intermediate quantity, or keep it as a variable?
- Coordinates and problem class are a choice; test them
- Redundant convex constraints on lifted quantities
- Starting points
- Smooth stand-ins for nonsmooth laws
- References
- See also

## Terminology used here

| Term | Meaning |
|---|---|
| **full-space formulation** | intermediate quantities are variables with defining equality constraints |
| **reduced-space formulation** | intermediate quantities are eliminated by substitution; fewer variables, denser expressions |
| **defined variable** | AMPL's mechanism for substitution: `var x = expr;` or a defining constraint under `option substout 1` (`nonlinear-programs.md`) |
| **lifting / auxiliary variable** | a new variable standing for an expression (`W = V^2`), often added so that structure (a cone, a bound) becomes visible |
| **redundant constraint** | a constraint implied by the others; it changes nothing at feasible points but can strengthen a relaxation |
| **convex relaxation** | a convex problem whose feasible set contains the original one; global solvers bound with it |
| **local vs. global solver** | a local solver returns a point satisfying first-order conditions; a global solver also proves a bound |
| **smoothing** | replacing a nonsmooth function (`max`, `abs`, a dead band) by a smooth approximation with a parameter that controls its accuracy |

## Substitute an intermediate quantity, or keep it as a variable?

**Substitute** (reduced space) when a variable only names an expression that is used
elsewhere, and nothing needs its bound, its dual or its name in the solver's problem.
Substitution removes the variable *and* its defining row. Measured on a large
power-network NLP: substituting every quantity that a row merely defined gave **25 % fewer
variables and rows** and a **1.7× faster** solve, with identical optima. The literature
reports the same direction when the eliminated quantities are many and the remaining
degrees of freedom few. It also reports the opposite when substitution makes the
remaining expressions dense or expensive to differentiate (e.g. Pacaud et al. 2023;
Parker et al. 2024). Measure it.

**Keep the variable** (full space) when it carries something the expression does not:

- **The name lets a structure be recognized.** A lifted `W = V^2` and
  `Wc = Vi*Vj*cos(...)` make a rotated second-order cone `Wc^2 + Ws^2 <= Wi*Wj` visible
  (see "Redundant convex constraints" below). With the lifts inlined, the same row is a
  degree-4 trigonometric expression that no solver treats as convex.
- **A bound has to reach the solver.** A defined variable carries no bounds or
  integrality: AMPL only substitutes unrestricted variables. If a named quantity has a
  bound that the expression's variables do not imply, keep it as a variable with its
  defining constraint. Measured: on a reliability model, the auxiliary standing for an
  `exp(...)` term was what made the model solvable at all. The conversion to the solver
  did not propagate bounds through the exponential, and the declared bound on the
  auxiliary did that work.
- **Its dual is needed.** The defining constraint's dual disappears with it. Sensitivity
  or gradient information read from that row must be read elsewhere, typically from the
  rows the substituted expression now appears in.
- **The inverse is not available in closed form.** `Vm^2 = E^2 + F^2` defines `Vm` only
  through a square root. Keep `Vm` as a variable.

**Keep both forms behind one switch** so the choice stays testable:

```ampl
param defvars binary default 1;           # 1 = substitute, 0 = full space

var FlowF {k in BRANCHES} >= -cap[k], <= cap[k];      # the full-space variable
var Flow {k in BRANCHES} =
   if defvars = 0 then FlowF[k]
   else g[k]*V[from[k]]^2 - V[from[k]]*V[to[k]]*(g[k]*cos(Th[from[k]]-Th[to[k]])
                                               + b[k]*sin(Th[from[k]]-Th[to[k]]));

subject to Flow_Def {k in BRANCHES: defvars = 0}:   # exists only in full space
   FlowF[k] = g[k]*V[from[k]]^2 - V[from[k]]*V[to[k]]*(g[k]*cos(Th[from[k]]-Th[to[k]])
                                                   + b[k]*sin(Th[from[k]]-Th[to[k]]));
```

The `if` tests a parameter, so AMPL resolves it when it generates the instance and the
solver sees one clean form. Before adopting the substituted form, solve both forms on the
same data and require the same objective to solver tolerance (measured agreement:
2.5e-9 and 3.8e-8). If the method uses duals or gradients, require those to agree too.

Two traps of the substituted form:

- **A defined variable cannot be assigned.** `let Flow[k] := ...` fails. A warm start
  must set the variables the expression is computed from.
- **Its bounds are gone.** Re-check that every bound dropped with the full-space variable
  was implied anyway. Measured before relying on it: sums of unit limits equalled the
  controller limits on every controller of every network used.

## Coordinates and problem class are a choice; test them

The same physics can often be written in different coordinates, and the choice changes
the problem class: polar against rectangular voltages in power flow, flows against
pressures in gas and water networks, or a product kept against one disaggregated per
choice. **No coordinate system is best for every solver.** The published evidence on AC
optimal power flow shows this. One FERC staff study found rectangular forms faster on
larger instances with local solvers (Castillo & O'Neill 2013). Another study found the
denser polar forms best for interior-point methods (Sadat & Kim 2021).

What each choice buys:

- **A polynomial (e.g. quadratically constrained) form** opens the model to solvers that
  only accept quadratic nonconvexity, and to conic and semidefinite relaxations (Jabr 2006).
- **The original transcendental form** usually has fewer variables and rows. Solvers that
  handle general nonlinear functions natively may do best on it.
- **A rewrite can silently leave a convex class.** Folding a product of a discrete choice
  and a continuous variable back into one nonconvex term (`A^2 * Vsq`) turned a convex
  mixed-integer second-order cone program into a nonconvex one. That cost 5× on one
  solver, and on another it went from a solution to none.

Measured on an AC optimal power flow with discrete transformer taps, both kept in a
global solve:

- The best formulation **kept the trigonometric (polar) equations** and *added* lifted
  variables plus one redundant convex row (next section).
- Rewriting the flow equations in terms of the lifted variables was sound. For the
  solver that was fastest on this model it turned proofs in 0.3–3.2 s into time-limit
  stops, so it was rejected.

**Recommendation:** when the physics allows several coordinate systems, keep the
alternatives available, through a switch as above or as sibling model files. Benchmark
them on the solvers you will actually use, and re-check when the solver changes. Before
any rewrite, note which problem class the current formulation is in (linear, convex
quadratic, SOCP, nonconvex polynomial, general nonlinear), and check whether the rewrite
leaves it.

## Redundant convex constraints on lifted quantities

A constraint that is an identity of the model's own definitions removes no feasible
point. It can still hand a global solver the convex bound it otherwise lacks. The
canonical example is the AC power-flow lift (Jabr 2006):

```ampl
# Lifted quantities as VARIABLES with defining rows and bounds -- not defined
# variables, which would be substituted back and hide the cone
var Wii {i in BUS} >= vmin[i]^2, <= vmax[i]^2;
var Wc {(i,j) in LINE} >= wc_lo[i,j], <= wc_hi[i,j];
var Ws {(i,j) in LINE} >= -ws_hi[i,j], <= ws_hi[i,j];
subject to Wii_Def {i in BUS}: Wii[i] = V[i]^2;
subject to Wc_Def {(i,j) in LINE}: Wc[i,j] = V[i]*V[j]*cos(Th[i]-Th[j]);
subject to Ws_Def {(i,j) in LINE}: Ws[i,j] = V[i]*V[j]*sin(Th[i]-Th[j]);
# Holds with equality at every point satisfying the definitions, and is a rotated cone:
subject to SOC {(i,j) in LINE}: Wc[i,j]^2 + Ws[i,j]^2 <= Wii[i]*Wii[j];
```

Measured: this single row took the medium instance from "no solver proves optimality in
60 s" to proofs in under a second. Combined with a disaggregated (per-tap) form of the
transformer flows, which made those rows linear in exactly the variables the cone bounds,
it was 5× better again. On its own the disaggregation made things *worse*: more variables
and no convex bound to use them. **Judge such changes together, not one at a time.**

Limits:

- The relaxation is exact only in special cases (e.g. radial networks). On meshed
  networks it is a cut, not a reformulation (Kocuk, Dey & Sun 2016).
- Tighter variants exist, such as the QC relaxation (Coffrin, Hijazi & Van Hentenryck
  2016).
- The redundant row needs finite, tight bounds on the lifted variables, derived from the
  base variables' declared bounds.

The general pattern: look for identities among your definitions (`x^2 + y^2 = r^2`,
`sum of shares = 1`, `product = constant`), and add the convex side as a constraint.

## Starting points

`nonlinear-programs.md` explains why the starting point matters for local solvers. Three
rules from field use:

- **Start from a consistent point, not just a plausible one.** Fixing the decisions and
  solving the remaining equations first (for example, a power flow before the optimal power
  flow) and starting the optimization there was 4–6× faster than starting from nominal
  values.
- **Derive the guess from data, never from a solve of the same model.** For example, use
  equal shares of a budget, nominal voltages, or the current operating state. A start near
  the optimum flatters whichever solver reads it, and makes timings meaningless.
- **Give every formulation being compared the same guess**, in the same terms, on the
  variables they share. Otherwise the comparison measures the starting point.

Operators whose domain excludes 0 (`log`, `sqrt` near 0, `1/x`, fractional powers) need
the guess in the `.mod` file (`:=`). Otherwise the first function evaluation can already
fail.

## Smooth stand-ins for nonsmooth laws

Controller dead bands, saturations, `max(0, x)` and `abs(x)` are nonsmooth. Local NLP
solvers handle them poorly, and an exact mixed-integer treatment may be too slow inside a
search. A standard compromise (smoothing: Chen & Mangasarian 1996; surrogate-based
optimization: Forrester & Keane 2009):

- **During search, use a smooth approximation** with an explicit accuracy parameter:
  `eps*log(1 + exp(x/eps))` (softplus) for `max(0, x)`;
  `sqrt(x^2 + delta^2) - delta` for `abs(x)`; `tanh` for a saturating response.
- **Report and certify in the exact model.** Re-solve or re-evaluate the final point with
  the exact law, and report that value. The smooth model's objective is not the answer.
- **State the approximation error** at the chosen parameter (e.g. "softplus error 1.4 % of
  the half range at eps = 0.02"). Check that the smooth curve passes where it must, such as
  a saturation corner. A smooth curve that never quite reaches a limit makes the exact
  re-solve misclassify which piece a point is on.
- **If the exact re-solve is infeasible**, solve an elastic version (`model-as-evaluator-and-heuristics.md`) to find the
  pieces that are wrong, move them, and retry. Do not loosen the exact model.

Complementarity is the same issue in another form. A switching law such as "regulate the
voltage until a limit, then hold the limit" is a complementarity condition
(`complementarity-problems.md`), and MP can reformulate `complements`
for solvers without native support.

## Further reading

The MP modeling guide summarizes these choices in "Nonlinear models: substitute or name"
(https://mp.ampl.com/modeling-formulations.html) and the redundant-cone technique in
"Redundant convex constraints on lifted variables"
(https://mp.ampl.com/modeling-expressions.html).

## References

- Castillo, A., O'Neill, R.P. (2013). *Computational Performance of Solution Techniques
  Applied to the ACOPF*. FERC Optimal Power Flow Paper 5.
- Chen, C., Mangasarian, O.L. (1996). A class of smoothing functions for nonlinear and
  mixed complementarity problems. *Comput. Optim. Appl.* 5, 97–138.
- Coffrin, C., Hijazi, H., Van Hentenryck, P. (2016). The QC relaxation: a theoretical
  and computational study on optimal power flow. *IEEE Trans. Power Syst.* 31(4).
- Forrester, A.I.J., Keane, A.J. (2009). Recent advances in surrogate-based optimization.
  *Prog. Aerospace Sci.* 45, 50–79.
- Jabr, R.A. (2006). Radial distribution load flow using conic programming. *IEEE Trans.
  Power Syst.* 21(3), 1458–1459.
- Kocuk, B., Dey, S.S., Sun, X.A. (2016). Inexactness of SDP relaxation and valid
  inequalities for optimal power flow. *IEEE Trans. Power Syst.* 31(1), 642–651.
- Pacaud, F., Shin, S., Schanen, M., Maldonado, D.A., Anitescu, M. (2023). Accelerating
  condensed interior-point methods on SIMD/GPU architectures. *J. Optim. Theory Appl.*,
  doi:10.1007/s10957-022-02129-5.
- Parker, R.B., Dowson, O., LoGiudice, N., Garcia, M., Bent, R. (2024). Formulations and
  scalability of neural network surrogates in nonlinear optimization problems.
  arXiv:2412.11403.
- Sadat, S.A., Kim, K. (2021). Numerical performance of different formulations for
  alternating current optimal power flow. arXiv:2107.07700.

## See also

- `nonlinear-programs.md` — initial values, `substout`, defined variables, range
  violations and local optima
- `../core-language/05-variables-objectives-constraints.md` — `var ... = expr`
  declarations
- `../mp-library/expressions-and-modeling-guide.md` — conic and general nonlinear
  expressions MP recognizes
- `choosing-formulations.md` — the corresponding choices for mixed-integer and logical
  models
- `model-as-evaluator-and-heuristics.md` — using a fixed version of the model to evaluate
  candidates, elastic restoration
- `../benchmarking-and-validation.md` — checking that a local `solved` and a timing mean
  what they seem to
