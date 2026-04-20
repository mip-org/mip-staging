# manopt

[Manopt](https://www.manopt.org) is a MATLAB toolbox for optimization on manifolds. It provides a collection of manifold definitions and optimization solvers for problems where the search space is a smooth manifold (spheres, Stiefel manifolds, Grassmannians, rotation matrices, etc.).

- **Author**: Nicolas Boumal
- **License**: GPL-3.0
- **Version**: 8.0
- **Repository**: https://github.com/NicolasBoumal/manopt

## Install

```matlab
mip install --channel mip-org/staging manopt
mip load manopt
```

## Features

- 18 manifold geometries (sphere, Stiefel, Grassmann, rotations, fixed-rank, positive-definite, etc.)
- 15+ solvers (trust-regions, conjugate gradient, BFGS, steepest descent, stochastic gradient, particle swarm, etc.)
- Automatic differentiation support
- Optional MEX acceleration for sparse operations and tensor-train manifolds

## MEX note

On supported architectures (Linux x86_64, macOS x86_64, macOS ARM64), pre-compiled MEX binaries provide full functionality for sparse matrix tools (`sparseentries`, `replacesparseentries`) and tensor-train manifolds. On other architectures, the core library works without MEX but those specific features will not be available.
