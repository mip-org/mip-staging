# safe (main)

[SAFE](https://safetoolbox.github.io/) (Sensitivity Analysis For Everybody) is a MATLAB toolbox for global sensitivity analysis, developed at the University of Bristol.

- **Authors**: Francesca Pianosi, Fanny Sarrazin, Thorsten Wagener
- **License**: GPL-3.0
- **Version**: main (branch-tracked)
- **Repository**: https://github.com/rebeccamccabe/SAFE-matlab (fork of https://github.com/SAFEtoolbox/SAFE-matlab)

## Why this release sources a fork

Upstream SAFE — both the v1.2.0 release (packaged here as `safe@1.2.0`) and
the current `main` — has a broken `PAWN/pawn_model_execution.m`: it calls
`model_evaluation`, a function that does not exist anywhere in the toolbox
(it was renamed to `model_execution`), so any PAWN analysis that executes a
model through it errors. This release tracks
[Rebecca McCabe's fork](https://github.com/rebeccamccabe/SAFE-matlab), whose
`main` is upstream `main` plus a one-line fix of that call. Everything else is
identical to upstream (the fork also adds upstream's LICENCE file and drops
two stray docs). If the fix is ever merged upstream and tagged, a regular
numeric release should supersede this one.

## Install

```matlab
mip install --channel mip-org/staging safe@main
mip load safe
```

Note the explicit `@main`: a bare `safe` resolves to the highest numeric
version in the channel (`1.2.0`, which points at unpatched upstream).

## What is shipped

The method directories, all on the path after `mip load safe`:

- `EET` — Elementary Effects Test (method of Morris)
- `RSA` — Regional Sensitivity Analysis
- `VBSA` — Variance-Based (Sobol') Sensitivity Analysis
- `FAST` — Fourier Amplitude Sensitivity Test
- `PAWN` — density-based sensitivity analysis
- `GLUE` — Generalized Likelihood Uncertainty Estimation
- `DYNIA` — Dynamic Identifiability Analysis
- `sampling`, `util`, `visualization` — sampling strategies (LHS, Morris/OAT), utilities, and plotting

The `workflow_*.m` demo scripts ship in the package root (not on the path).

## What is not shipped

To keep the bundle small, the upstream `example/` directory (demo models such
as hymod and hbv, plus their data files, used by the workflow scripts) and the
12 MB `PAWN/SWAT_samples.mat` demo dataset are removed. Get them from the
[source repository](https://github.com/rebeccamccabe/SAFE-matlab) if you want
to run the workflow scripts.

## Tests

`test_safe.m` runs an Elementary Effects Test (Morris sampling) on the
Ishigami-Homma function, `empiricalcdf`, and `pawn_model_execution` on a small
generated model — the last of these exercises the fork's fix and fails against
unpatched upstream. The test needs no MathWorks toolboxes. Note that parts of
SAFE itself do: `AAT_sampling`/`OAT_sampling` use inverse CDFs (`unifinv`, ...)
and Latin hypercube sampling uses `pdist`, all from the Statistics and Machine
Learning Toolbox.
