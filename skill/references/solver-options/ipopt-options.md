# IPOPT Options

Derived from: ipopt-asl-options.md

Source: `raw/ipopt-asl-options.md` (`https://dev.ampl.com/solvers/ipopt/options.html`),
current as of 2026-10-28. IPOPT's AMPL driver is **not** MP-based: the page lists only
the 56 keywords the AMPL interface knows, with a one-line description each and **no
defaults or value ranges** (those are in IPOPT's own documentation, and `option_file_name`
/ `ipopt.opt` accepts any IPOPT option). This file groups them; it does not add values
the source doesn't give.

IPOPT is a local interior-point solver for smooth continuous NLP: no integer variables,
no global optimality guarantee on nonconvex models (`../core-language/13-solver-selection-guide.md`,
`../benchmarking-and-validation.md`). MP's reformulations (e.g. of `complements`) reach
it through MP2NL (`mp2nl-options.md`).

## Setting options

```ampl
option solver ipopt;
option ipopt_options 'print_level=5 max_iter=3000 tol=1e-8';
solve;
```

Through MP2NL, IPOPT's own keywords stay in `ipopt_options`, MP's in `mp2nl_options`:

```python
ampl.solve(solver="mp2nl",
           mp2nl_options="solver=ipopt cvt:compl=2 cvt:compl:eps=1e-8 lim:time=60",
           ipopt_options="print_level=0")
```

## Keywords by purpose

| Purpose | Keywords |
|---|---|
| Verbosity and output | `print_level`, `outlev`, `output_file`, `file_print_level`, `print_user_options`, `print_options_documentation`, `wantsol` |
| Limits | `max_iter` (`maxit`), `max_cpu_time` |
| Convergence | `tol`, `dual_inf_tol`, `constr_viol_tol`, `compl_inf_tol`; "acceptable" level: `acceptable_tol`, `acceptable_dual_inf_tol`, `acceptable_constr_viol_tol`, `acceptable_compl_inf_tol` |
| Barrier parameter | `mu_strategy`, `mu_oracle`, `mu_init`, `mu_max` |
| Initial point and bounds | `bound_push`, `bound_frac`, `slack_bound_push`, `slack_bound_frac`, `bound_relax_factor`, `honor_original_bounds`, `bound_mult_init_val`, `constr_mult_init_max` |
| Warm start | `warm_start_init_point`, `warm_start_bound_push`, `warm_start_mult_bound_push` |
| Scaling | `nlp_scaling_method`, `nlp_scaling_max_gradient`, `obj_scaling_factor`, `linear_system_scaling`, `linear_scaling_on_demand` |
| Linear solver | `linear_solver`, `ma27_pivtol`, `ma27_pivtolmax`, `ma57_pivtol`, `ma57_pivtolmax`, `ma57_pivot_order`, `pardiso_matching_strategy`, `min_refinement_steps`, `max_refinement_steps` |
| Hessian | `hessian_approximation` (quasi-Newton approximation instead of exact second derivatives) |
| Robustness | `max_soc`, `watchdog_shortened_iter_trigger`, `required_infeasibility_reduction`, `expect_infeasible_problem`, `diverging_iterates_tol`, `alpha_for_y`, `halt_on_ampl_error` |
| Options file | `option_file_name` (default `ipopt.opt`) |

`honor_original_bounds`: if set to no, the solution might slightly violate bounds.
`halt_on_ampl_error`: exit with a message on a function-evaluation error — relevant for
`log`, `sqrt` and similar functions near the edge of their domain
(`../modeling-patterns/nonlinear-programs.md`).

## See also

- `knitro-options.md` — the other common local NLP solver, with integer support
- `../modeling-patterns/nlp-formulation-choices.md` — starting points, smoothing
- Exhaustive keyword list: `raw/ipopt-asl-options.md`
