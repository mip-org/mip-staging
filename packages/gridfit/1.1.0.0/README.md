# gridfit

Estimates a smooth surface on a 2D grid from scattered `(x, y, z)` data
using a ridge-regularized least-squares fit. Unlike a pure interpolant,
`gridfit` lets you trade data fidelity against surface smoothness via
the `'smoothness'` parameter, and it extrapolates cleanly to the grid
boundaries.

- Upstream: https://www.mathworks.com/matlabcentral/fileexchange/8998-surface-fitting-using-gridfit
- Author: John D'Errico
- Version: 1.1.0.0
- License: BSD-2-Clause

## What is shipped

After `mip load`, the `gridfitdir/` directory is on the MATLAB path so
you can call `gridfit(...)` directly. The upstream `gridfitdir/test/`
directory ships as well but is not on the path.

## What is not shipped

The upstream `gridfitdir/demo/` folder (walkthrough `.mlx` livescript
plus pre-rendered HTML/PNG output, ~1.5 MB) and `gridfitdir/doc/`
(PDF + EPS + RTF write-ups, ~3.7 MB) are stripped from the bundle to
keep the archive lean. Grab them from the File Exchange page linked
above if you want them.

## Install

```matlab
mip install --channel mip-org/staging gridfit
mip load gridfit
```

## Usage

```matlab
% Scattered samples of some surface
x = rand(500, 1) * 10;
y = rand(500, 1) * 10;
z = sin(x) + cos(y);

% Fit a smooth 21x21 grid
xnodes = linspace(0, 10, 21);
ynodes = linspace(0, 10, 21);
[zgrid, xgrid, ygrid] = gridfit(x, y, z, xnodes, ynodes, 'smoothness', 1);

surf(xgrid, ygrid, zgrid);
```
