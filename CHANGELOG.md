# Changelog

## 2026-06-24

- Added `fmm3d` 2.1.0 (Flatiron Institute Fast Multipole Methods in 3D).
  Source points at the real `flatironinstitute/fmm3d` (tag `v2.1.0`); built
  from the upstream Fortran via the makefile (no transpile). Ships native MEX
  for `linux_x86_64`, `macos_arm64`, and `windows_x86_64`: two gateways,
  `fmm3d` (modern API) and `fmm3d_legacy` (legacy CMCL API). `-march=native`
  is dropped for portability; other-language bindings and the vectorized
  `FAST_KER` kernels are trimmed.

## 2026-06-22

- Added `finufft` 2.5.1 with a `numbl_wasm` build. Source points at the real
  `flatironinstitute/finufft` (tag `v2.5.1`); the numbl mex shim + builtin
  (`matlab/numbl/`) is carried in-channel, replacing the magland/finufft fork
  that previously baked it in-tree. Also builds the native MEX
  (`linux_x86_64`, `macos_arm64`, `windows_x86_64`).
- `numbl_wasm` added to the `build-package.yml` architecture choices so push
  builds can dispatch it (the reusable workflow already supports it).
- Build-request issues opened by an admin (write+ on the repo) now dispatch
  automatically — no `approve` comment needed. README updated.
