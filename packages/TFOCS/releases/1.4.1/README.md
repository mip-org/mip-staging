# TFOCS

[TFOCS](http://cvxr.com/tfocs/) (Templates for First-Order Conic Solvers, pronounced "tee-fox") is a MATLAB library for solving convex optimization problems via first-order methods. It provides building blocks (smooth functions, proximity operators, projections, linear operators) for constructing efficient solvers.

- **Authors**: Stephen Becker, Emmanuel Candes, Michael Grant
- **License**: BSD-3-Clause
- **Version**: 1.4.1
- **Repository**: https://github.com/cvxr/TFOCS

## Install

```matlab
mip install --channel mip-org/staging TFOCS
mip load TFOCS
```

## Features

- Premade solvers for LASSO, basis pursuit, Dantzig selector, SDP relaxations, and more
- Proximity operators for L1, L2, nuclear norm, total variation, etc.
- Smooth function templates (quadratic, Huber, log-determinant, entropy, etc.)
- Linear operator algebra (compose, scale, adjoint)
- Continuation and warm-starting support

## MEX note

On supported architectures, optional MEX files accelerate soft-thresholding and certain proximal operators. All MEX-accelerated functions have pure-MATLAB fallbacks, so TFOCS is fully functional without compilation.
