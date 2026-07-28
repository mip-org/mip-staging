# Changelog

## Unreleased

- Replaced `librla@1.1.1` with `librla@1.2.0`: upstream deleted the `v1.1.1`
  tag days after we shipped it (leaving the recipe unrebuildable) and released
  `v1.2.0`, which properly bumps the internal version headers, adds dense
  materialization in `get_matrix`, and lifts the rank-mode-only restriction on
  matrix-free `LinearOperator`s. Same recipe otherwise; the test now also
  covers matrix-free tolerance mode. The `librla-1.1.1` GitHub release
  remains as an orphan (its `.mhl` was built from the same history).
- Added `librla@1.1.1` (randomized linear algebra library by Adrianna Gillman
  and Zydrunas Gimbutas; MIT; arXiv:2607.20732). Pure MATLAB (`any`), fetched
  from the upstream `distrib/matlab/` subdirectory at tag `v1.1.1` — the
  Python and Julia implementations are not shipped. Provides sketching-based
  low-rank QR/SVD/ID with tolerance and rank modes, a deterministic ID, and a
  matrix-free `LinearOperator` class. Upstream `demo/` and `test/` are opt-in
  via `--with examples` / `--with tests`. `test_librla.m` exercises all five
  public routines against a full-SVD reference plus the LinearOperator path.
- Added `safe@main`, branch-tracking rebeccamccabe/SAFE-matlab (upstream
  `main` plus a one-line fix: `PAWN/pawn_model_execution.m` calls
  `model_evaluation`, which doesn't exist anywhere in the toolbox — broken in
  upstream v1.2.0 and `main` alike). Same trims and layout as `safe@1.2.0`;
  the test additionally exercises `pawn_model_execution` on a generated
  model, which fails against unpatched upstream. Needed by
  symbiotic-engineering/MDOcean (PR #299), whose old SAFE submodule pointed
  at this fork; bare `safe` still resolves to `1.2.0`, so pin `safe@main`.
- Added `kwave@1.4.1` (k-Wave acoustic/ultrasound simulation toolbox by Bradley
  Treeby, Ben Cox, et al., UCL; LGPL-3.0-or-later). Pure MATLAB (`any`), fetched
  from the upstream `k-Wave/` subdirectory at tag `v1.4.1`. `mip load kwave` is
  k-Wave's own install step (add the `k-Wave` folder to the path); `info.xml` +
  `helpfiles/` keep the in-browser docs. `examples/` and `testing/` are opt-in
  via `--with`. The optional accelerated C++/CUDA solver binaries are not part
  of the toolbox (users download them from k-wave.org), so there is nothing
  platform-specific to build. `test_kwave.m` checks core utilities and runs a
  tiny headless `kspaceFirstOrder2D` initial-value problem in base MATLAB.
- Added `pivlab@3.12.001` (PIVlab particle image velocimetry tool by William
  Thielicke; MIT). Compiles 5 MEX from source on the three CI arches
  (`+plot/fastLICFunction` LIC renderer plus minFunc's
  mcholC/lbfgsC/lbfgsAddC/lbfgsProdC for wOFV), with an `[any]` pure-MATLAB
  fallback. Trims `resources/`, `docs/`, `Example_data/`, and the proprietary
  PCO/Teensy hardware-acquisition binaries. The PIV engine needs the Image
  Processing Toolbox at runtime (absent on CI), so the channel tests exercise
  layout, `misc.smoothn`/`misc.inpaint_nans`, and all shipped MEX.
- Added `safe@1.2.0` (SAFE global sensitivity analysis toolbox from the
  University of Bristol: EET/Morris, RSA, Sobol'/VBSA, FAST, PAWN, GLUE,
  DYNIA; GPL-3.0, pure MATLAB, `any` arch). The upstream `example/` dir and
  the 12 MB `PAWN/SWAT_samples.mat` demo dataset are removed — the latter via
  the new `remove_files:` field in `source.yaml`, added to
  `mip_channel_tools` alongside this (build after that lands on tooling
  `main`). Note SAFE's `AAT_sampling`/`OAT_sampling` need the Statistics and
  Machine Learning Toolbox at runtime.
- Added `wec-sim@7.1.0` (WEC-Sim wave energy converter simulator from
  NREL/Sandia; Apache-2.0, pure MATLAB, `any` arch). `remove_dirs` trims
  `examples`/`docs`/`tutorials`/`tests` (~650 MB checkout → 8 MB bundle);
  paths mirror upstream `addWecSimSource.m`, with explicit entries for the
  Simulink `.slx` library dirs that `recursive` skips. Running simulations
  requires Simulink/Simscape/Simscape Multibody; `test_wec_sim.m` smoke-tests
  the pure-MATLAB surface only.
- Added `vtktoolbox@master` (KIT-IBT's MEX interface to VTK: file I/O and
  filters for VTK datasets as MATLAB structs; MPL-2.0, branch-tracked, no
  tags). `compile.m` builds a minimal static VTK 9.5.2 from source (19
  modules, no rendering) in a scratch prefix, then drives the upstream
  CMakeLists to produce the 29 MEX into `MATLAB/`; Linux gets a patchelf
  `DT_NEEDED` normalization pass, macOS uses Apple Clang, Windows uses MSVC
  (VS generator). `test_vtktoolbox.m` functionally exercises all 29 MEX.
  Windows builds define `_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR` (both cmake
  stages): VTK ParallelCore locks a static `std::mutex` at DLL attach, which
  faults against MATLAB's older bundled MSVCP140.dll and made
  `vtkIntegrateAttributes.mexw64` fail to load (same issue/fix as gptoolbox).

- Added `surfacefun@master` (Dan Fortunato's high-order surface-PDE package;
  pure MATLAB, `any` architecture). Depends on `chebfun` (declared as a mip
  dependency, replacing the upstream `external/chebfun` git submodule);
  `docs/` (~24 MB of Sphinx sources) is trimmed. `demo/` and `apps/` ship as
  the `examples` extra-paths group. Upstream has no formal license file;
  carried as `license: unspecified` (intentionally permissive) per channel
  owner's direction.

- Add `sdpt3@master` (numbl_wasm) and `tfocs@1.4.1` (MEX linux/macos + `any`
  fallback), ported from an older packaging system. Renamed each `recipe.yaml`
  to `source.yaml`; dropped the obsolete `symbol_extensions` field from
  `sdpt3`'s `mip.yaml`; added `test_tfocs.m` exercising `proxAdaptiveL1Mex`
  (the MEX-coverage gate rejects a built-but-unexercised MEX).

## 2026-06-30

- `fmm2d` (numbl_wasm): define `flong` (`int64_t`) in `fmm2d_c.h`. fort2c emits
  `flong`-typed temps for allocatable-array capacities (the `*_acap` vars), but
  the runtime header only defined `fint`/`fcomplex`, so the generated C failed
  to compile ("undeclared identifier 'flong'").

## 2026-06-25

- Added `fmm3dbie` (fast multipole accelerated boundary integral equation
  solvers in 3D). Source points at `fastalgorithms/fmm3dbie`, tracking `master`
  (no release tags). The single `fmm3dbie_routs` mwrap gateway statically links
  the vendored FMM3D submodule (fetched via the new `submodules: true` source
  flag). Declares a dependency on the sibling `fmm3d` package.
  - Native MEX for `linux_x86_64`, `macos_arm64`, `windows_x86_64`, built from
    the upstream Fortran via the makefile (no transpile). `-march=native` is
    dropped for portability; other-language bindings and the example/test/doc
    trees (and the same in the FMM3D submodule) are trimmed. BLAS/LAPACK resolve
    to MATLAB's `libmwblas`/`libmwlapack`.
  - No `numbl_wasm` build: unlike fmm3d, fmm3dbie links BLAS/LAPACK, which has no
    MATLAB-provided equivalent under wasm; deferred to a follow-up.

- `build-package` caller: repoint from `@staging` to `@main` and forward the
  `publish` and `source_repo` inputs to the reusable workflow. Test builds
  (`publish` unchecked) now publish the `.mhl` to a rolling `_test-builds`
  prerelease with a direct download URL, instead of leaving it only as a
  workflow artifact.

## 2026-06-24

- Added `fmm3d` 2.1.0 (Flatiron Institute Fast Multipole Methods in 3D).
  Source points at the real `flatironinstitute/fmm3d` (tag `v2.1.0`). Two
  mwrap gateways, `fmm3d` (modern API) and `fmm3d_legacy` (legacy CMCL API).
  - Native MEX for `linux_x86_64`, `macos_arm64`, `windows_x86_64`, built from
    the upstream Fortran via the makefile (no transpile). `-march=native` is
    dropped for portability; other-language bindings and the vectorized
    `FAST_KER` kernels are trimmed.
  - `numbl_wasm` build: the Fortran is transpiled to C with `fort2c` and
    compiled to `fmm3d.wasm` / `fmm3d_legacy.wasm` with Emscripten, dispatched
    by the `fmm3d.numbl.js` / `fmm3d_legacy.numbl.js` builtins (`matlab/numbl/`).
    Requires `fort2c` features (ENTRY/FORMAT/STOP, INTEGER*8 conversions, large
    machine-generated tables) added upstream in `magland/fort2c`.

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
