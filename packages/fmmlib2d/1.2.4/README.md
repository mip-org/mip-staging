# fmmlib2d

[FMMLIB2D](https://github.com/zgimbutas/fmmlib2d) evaluates potential fields
due to particle sources governed by either the Laplace or Helmholtz equation
in R^2, using the Fast Multipole Method. The core is Fortran and is called
from MATLAB through a pre-generated mwrap gateway (`matlab/fmm2d.c`).

- **Authors**: Leslie Greengard and Zydrunas Gimbutas
- **License**: BSD-3-Clause
- **Version**: 1.2.4
- **Repository**: https://github.com/zgimbutas/fmmlib2d

## Install

```matlab
mip install --channel mip-org/staging fmmlib2d
mip load fmmlib2d
```

## What is shipped

The `matlab/` directory is placed on the MATLAB path. That exposes the
particle FMM entry points (`rfmm2dpart`, `lfmm2dpart`, `cfmm2dpart`,
`zfmm2dpart`, `hfmm2dpart`), the direct evaluators
(`r2dpartdirect`, `l2dpartdirect`, `c2dpartdirect`, `z2dpartdirect`,
`h2dpartdirect`), the tree utilities (`d2tstrcr`, `d2tstrcrem`,
`d2tgetb`, `d2tgetl`), and `fmm2dprini`.

## Architectures

Pre-compiled MEX binaries ship for `linux_x86_64`, `macos_x86_64`, and
`macos_arm64`. Windows is not currently built. There is no pure-MATLAB
fallback — the package needs the MEX to do any work.

The Linux MEX statically links `libgfortran`, `libquadmath`, `libstdc++`,
and `libgcc` so it runs on end-user machines that do not have a matching
gfortran runtime installed. The macOS MEX statically links `libgfortran`
and `libquadmath`; `libc++` and the system runtime come from the OS.

OpenMP is not enabled in the bundled build; for parallel runs, build
from upstream following `matlab/makefile.mwrap`.

## Test

`test_fmmlib2d.m` exercises `rfmm2dpart`, `lfmm2dpart`, and `hfmm2dpart`
against the direct evaluators at `iprec=4` (target ~1e-6) and asserts
relative error below 1e-3.
