# MP2NL Options

Derived from: mp2nl-mp-options.md, mp-tools-and-details.md (Meta-driver MP2NL)

Source: `raw/mp2nl-mp-options.md` (`https://dev.ampl.com/solvers/mp2nl/options.html`),
current as of 2026-10-28 (201 entries). MP2NL is a **meta-driver**: it applies MP's
reformulations (`acc:...`, `cvt:...`) and then calls any AMPL solver that reads NL
files — the *subsolver*. How to use it, where options go and how to choose the subsolver
are in `../mp-library/tools-troubleshooting-and-reformulation.md` ("The MP2NL
meta-driver"); this file lists the option families.

## Setting options

```ampl
option solver mp2nl;
option mp2nl_options 'solver=baron';             # MP's options, incl. the subsolver
option baron_options 'outlev=1 iisfind=1';       # the subsolver's own options
solve;
```

Two strings, two vocabularies: `mp2nl_options` takes MP's options; `<subsolver>_options`
takes the subsolver's own keywords. `nl:solver_options` (`solver_options`) can carry the
subsolver's options for convenience, but `<subsolver>_options` is the preferred and
dominating way. Knitro, BARON, CONOPT and LINDO Global have the bridge built in
(`mp2nl=1` in their own option string); then pass MP's `cvt:...`/`sol:chk:...` options
through `mp_options`.

## The `nl:` family (meta-driver control)

| Option | Effect |
|---|---|
| `nl:solver` (`solver`) | The subsolver; sets its configuration automatically if known |
| `nl:config` (`config`) | Pick a configuration (for a subsolver binary with another name) |
| `nl:printconfigs` (`printconfigs`) | Print the known configurations: which constructs are linearized (`acc:...=0`) and which defaults are set (e.g. `cvt:compl`) for each subsolver |
| `nl:stub` (`stub`) | Keep the reformulated NL (and SOL) file under this stub, to inspect what the subsolver received or attach to a support request |
| `nl:assign:defvar` (`nldefvar`) | Reference count above which an algebraic expression becomes a defined variable in the NL file (default 1; applied after `cvt:expr:nlassign`) |
| `nl:text`, `nl:comments` | Write a text NL file / with comments |

## Generic options passed on

`lim:time` (`timelim`), `mip:gap`, `mip:gapabs` are translated into the subsolver's own
keyword when MP2NL knows it (e.g. Knitro's `maxtime`; `outlev=1` shows the result in the
log) and can be set per objective in a multi-objective solve (suffix `.option_timelim`).
`tech:outlev`, `tech:timing`, `alg:start`, `alg:relax`, `obj:multi*` and the solution
check `sol:chk:*` work as in every MP driver.

## Acceptance and reformulation

The `acc:` family (55 entries) says what the subsolver receives natively, and the `cvt:`
family (87 entries) how MP reformulates the rest. Notable for NL subsolvers:

- `cvt:compl` — complementarity reformulation (default 0): 0 disjunction
  `a<=0 || b<=0` (needs integer variables), 1 product `a*b = cvt:compl:tol`, 2
  Fischer-Burmeister `sqrt(a^2+b^2+2*cvt:compl:tol) = a+b`, 3 `min(a,b) = 0` (nonsmooth).
  `cvt:compl:tol` (`cvt:compl:eps`) default 1e-9.
- `cvt:pre:disj2ind` — recovers indicators from `b = 1 ==> C`, also under full
  linearization (e.g. `config=knitro`).

Logic is reformulated with binary variables, so the subsolver must accept the problem
class *after* reformulation: logic needs an MINLP subsolver; complementarity alone, with
a smooth reformulation, can go to an NLP solver.

## See also

- `../mp-library/tools-troubleshooting-and-reformulation.md` — MP2NL in practice
- `knitro-options.md`, `ipopt-options.md` — common subsolvers
- `../modeling-patterns/complementarity-problems.md`
- Exhaustive option list: `raw/mp2nl-mp-options.md`
