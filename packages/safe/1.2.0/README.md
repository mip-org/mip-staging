# safe

[SAFE](https://safetoolbox.github.io/) (Sensitivity Analysis For Everybody) is a MATLAB toolbox for global sensitivity analysis, developed at the University of Bristol.

- **Authors**: Francesca Pianosi, Fanny Sarrazin, Thorsten Wagener
- **License**: GPL-3.0
- **Version**: 1.2.0
- **Repository**: https://github.com/SAFEtoolbox/SAFE-matlab

## Install

```matlab
mip install --channel mip-org/staging safe
mip load safe
```

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
[upstream repository](https://github.com/SAFEtoolbox/SAFE-matlab) if you want
to run the workflow scripts.

## Tests

`test_safe.m` runs an Elementary Effects Test (Morris sampling) on the
Ishigami-Homma function, plus `empiricalcdf`. The test needs no MathWorks
toolboxes. Note that parts of SAFE itself do: `AAT_sampling`/`OAT_sampling`
use inverse CDFs (`unifinv`, ...) and Latin hypercube sampling uses `pdist`,
all from the Statistics and Machine Learning Toolbox.
