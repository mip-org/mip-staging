# Adding a Package to mip-staging

This document explains how to add a new MATLAB package to this channel from a
GitHub repository URL. Each package is described by a small set of YAML and
MATLAB files under `packages/<package_name>/releases/<version>/`. On every
push to `main`, GitHub Actions clones the upstream source per `recipe.yaml`,
overlays the channel-provided files, runs `mip bundle` (which compiles MEX if
needed), publishes `.mhl` archives, and updates the channel index.

Look at the existing packages in [mip-staging/packages/](packages/) and
[mip-core/packages/](../mip-core/packages/) — they are the best reference for
real-world examples of the patterns described below.

---

## Step 1 — Investigate the upstream repository

Before creating any files, clone the repository into a working directory
(outside this channel repo) and read through it:

```bash
git clone https://github.com/<owner>/<repo> /tmp/<repo>
```

Things to determine:

1. **License.** Open `LICENSE`, `LICENSE.txt`, `COPYING`, or the README. Only
   open-source licenses that permit redistribution are acceptable
   (MIT, BSD-2/3-Clause, Apache-2.0, GPL-2.0/3.0, LGPL, MPL-2.0, etc.). If
   no license is present, the project is **not** redistributable — stop. If
   the project is clearly source-available but the file is missing, ask the
   upstream author to clarify before proceeding. Record the SPDX identifier
   to use as the `license:` field in `mip.yaml`. If the source is intentionally
   permissive but lacks an SPDX file, use `unspecified` (see
   [kdtree](packages/../../mip-core/packages/kdtree/releases/master/mip.yaml)).

2. **Security review.** Skim the source for anything that would make
   distribution inappropriate: hard-coded credentials, unsanitized `eval` of
   untrusted input, network calls to suspicious endpoints, large pre-built
   binaries of unclear provenance, vendored dependencies under restrictive
   licenses. If anything looks problematic, do not include the package.

3. **Version selection.** Look at the repository's tags
   (`git tag --sort=-v:refname | head`) and releases page. Choose either:
   - **A tagged release** — preferred for stability. The version string
     will be the tag name with any `v`/`V` prefix stripped, normalized to a
     numeric form like `x`, `x.y`, or `x.y.z` (e.g. tag `v1.4.1` →
     version `1.4.1`, tag `Release_8.0` → version `8.0`).
   - **The default branch (`main` or `master`)** — when the project has no
     tags, or you specifically want the latest development tip. Use `main`
     or `master` literally as the version string.

4. **MATLAB layout.** Identify which subdirectories contain the `.m` files
   that users should have on their MATLAB path. Common patterns:
   - All `.m` files at the repo root → `addpaths: [{path: "."}]`
   - A `matlab/` subdirectory → `addpaths: [{path: "matlab"}]`
   - A nested toolbox tree where every directory matters →
     `addpaths: [{path: ".", recursive: true}]`

5. **MEX / native code.** Look for `.c`, `.cpp`, `.cu`, `.f`, `.f90` files
   alongside MATLAB sources, or `mex` calls in the README/install
   instructions. If MEX compilation is required, you will need a
   `compile.m`. Note the architectures the upstream supports — most C/C++
   MEX builds work on `linux_x86_64`, `macos_x86_64`, `macos_arm64`, and
   `windows_x86_64`, but Fortran or CUDA may be more restrictive.

6. **Package name normalization.** The directory name under `packages/`
   must use **underscores instead of hyphens** (the bundling pipeline
   rejects hyphens — see
   [scripts/prepare_packages.py:257](scripts/prepare_packages.py#L257)).
   Convert `my-cool-pkg` → `my_cool_pkg`. The `name:` field in `mip.yaml`
   must match this directory name exactly.

7. **Existing `mip.yaml`.** If the upstream repository already ships a
   valid `mip.yaml` at its root (or at the path that becomes the package
   root after `subdirectory`/`remove_dirs` are applied), you do **not**
   need to provide one in the channel — `recipe.yaml` alone is enough.
   Most third-party projects will not ship one, so you will be writing it.

---

## Step 2 — Create the release directory

```
packages/<package_name>/releases/<version>/
  recipe.yaml      # required — where to fetch the source from
  mip.yaml         # required unless the upstream repo provides one
  compile.m        # optional — only if MEX/native compilation is needed
  test_<package_name>.m   # optional but strongly recommended
  README.md        # optional — short user-facing description
  example.m        # optional — runnable usage example
```

The `<version>` directory name must match the `version:` field in
`mip.yaml` (e.g. directory `8.0/` ↔ `version: "8.0"`).

---

## Step 3 — Write `recipe.yaml`

`recipe.yaml` tells the prepare step where to fetch the upstream source.
The source spec is processed by
[scripts/prepare_packages.py](scripts/prepare_packages.py).

### Minimal form (clone default branch)

```yaml
source:
  git: "https://github.com/<owner>/<repo>"
```

### All supported fields

```yaml
source:
  git: "https://github.com/<owner>/<repo>"   # repo URL (required if using git)
  branch: "v1.4.1"                            # branch OR tag name (optional)
  subdirectory: "matlab"                      # extract only this subdir (optional)
  remove_dirs: [tests, examples, docs]        # delete these dirs after clone (optional)
```

### Alternate: ZIP source

If a project does not have a public git repo, a direct ZIP URL works:

```yaml
source:
  zip: "https://example.com/path/to/release.zip"
```

### Notes

- `branch:` accepts either a branch name (`main`, `master`) **or** a tag
  name (`v1.4.1`, `Release_8.0`) — git treats both the same for cloning.
- `subdirectory:` is useful when a repo contains the MATLAB code under a
  nested folder (e.g. `manopt/` inside the `manopt` repo — see
  [manopt recipe.yaml](packages/manopt/releases/8.0/recipe.yaml)).
- `remove_dirs:` is useful for trimming large test/demo folders that
  bloat the bundle.
- The `.git/` directory is automatically removed after clone.

---

## Step 4 — Write `mip.yaml`

`mip.yaml` is the package manifest. It is consumed by
[`mip.config.read_mip_yaml`](../mip/+mip/+config/read_mip_yaml.m) and the
build pipeline in [`+mip/+build/`](../mip/+mip/+build/).

### Minimal form (pure MATLAB, no compilation)

```yaml
name: my_package
description: "One-line description of the package."
version: "1.0.0"
license: "MIT"
homepage: "https://github.com/owner/repo"
repository: "https://github.com/owner/repo"
dependencies: []

addpaths:
  - path: "."

builds:
  - architectures: [any]
```

### All supported top-level fields

| Field | Type | Description |
| --- | --- | --- |
| `name` | string | Package name. **Required.** Must match the directory name and use underscores. |
| `version` | string | Version string. Must match the release directory name. Quote it (`"1.0"`) so YAML doesn't coerce it to a number. |
| `description` | string | Short human-readable summary. |
| `license` | string | SPDX license identifier (e.g. `"MIT"`, `"BSD-3-Clause"`, `"Apache-2.0"`, `"GPL-3.0"`). |
| `homepage` | string | Project homepage URL. |
| `repository` | string | Source repository URL. |
| `dependencies` | list of strings | Other mip packages this one needs at load time (e.g. `["chebfun"]` — see [surfacefun](../mip-core/packages/surfacefun/releases/master/mip.yaml)). Resolved via mip's normal channel priority. |
| `addpaths` | list | Default `addpath` entries (see below). May be overridden per-build. |
| `release_number` | int | Release counter. Bump this when you republish without changing source/version (e.g. to fix a packaging bug). Defaults to `1`. May also be set per-build. |
| `builds` | list | One or more build entries (see below). **Required.** |

### `addpaths`

Each entry adds one or more directories to the MATLAB path when the
package is loaded. Resolved by
[`+mip/+build/compute_addpaths.m`](../mip/+mip/+build/compute_addpaths.m).
Two forms are accepted:

```yaml
addpaths:
  - path: "matlab"                  # add a single directory (relative to package root)
  - path: "."                       # the package root itself
    recursive: true                 # add this dir AND every subdir containing .m files
    exclude: ["test", "paper"]      # skip these subdir names when recursing
```

`recursive: true` walks the tree and includes any directory that contains
at least one `.m` file. Directories starting with `.`, `+` (MATLAB
namespaces), or `@` (MATLAB classes) are automatically excluded — MATLAB
discovers those without an explicit `addpath`. See
[FLAM mip.yaml](../mip-core/packages/FLAM/releases/master/mip.yaml) for a
recursive example.

### `builds`

The `builds:` list is a sequence of build entries. When `mip bundle` runs
on a target architecture, it picks the **first** entry whose
`architectures:` list contains an exact match, falling back to the first
entry that lists `any`
([match_build.m](../mip/+mip/+build/match_build.m)).

Each build entry may contain:

| Field | Description |
| --- | --- |
| `architectures` | List of architecture strings this build applies to. **Required.** |
| `compile_script` | Path (relative to package root) to a MATLAB script that compiles MEX/native code. Run by [`run_compile.m`](../mip/+mip/+build/run_compile.m). |
| `test_script` | Path to a MATLAB script that exercises the package after install. Run by `mip test`. |
| `release_number` | Per-build release counter override. |
| `addpaths` | Per-build override of the top-level `addpaths`. |

Supported architecture values (used by `mip.arch()`):

- `linux_x86_64`
- `macos_x86_64`
- `macos_arm64`
- `windows_x86_64`
- `any` — pure-MATLAB packages that work everywhere

### Common patterns

**Pure MATLAB, runs anywhere:**

```yaml
builds:
  - architectures: [any]
```

**MEX-compiled package with one test script for all platforms:**

```yaml
builds:
  - architectures: [linux_x86_64, macos_x86_64, macos_arm64, windows_x86_64]
    compile_script: compile.m
    test_script: test_my_package.m
```

**MEX where some platforms can compile and others fall back to pure
MATLAB** (see
[manopt mip.yaml](packages/manopt/releases/8.0/mip.yaml)):

```yaml
builds:
  - architectures: [linux_x86_64, macos_x86_64, macos_arm64]
    compile_script: compile.m
    test_script: test_my_package_mex.m
  - architectures: [any]
    test_script: test_my_package.m
```

The `[any]` entry acts as a catch-all for architectures not listed
explicitly (e.g. `windows_x86_64` here would get the pure-MATLAB build).
Always keep an `[any]` fallback when the MEX layer is optional — it lets
users on unusual architectures still load the pure-MATLAB parts.

When you have a MEX build **and** an `[any]` fallback, use **two test
scripts** — one per build entry (see Step 6). The MEX build should test
at least one compiled function so a broken build/link is caught by
`mip test`; the `[any]` build tests only the pure-MATLAB layer.

---

## Step 5 — Write `compile.m` (only if needed)

If your `mip.yaml` references `compile_script: compile.m`, you must
provide it. The script:

- Runs with `pwd` set to the **package source root** (the directory that
  contains the cloned upstream source plus overlaid channel files).
- Should compile every MEX file the package needs and place the output
  next to its source (so the existing `addpath` entries pick it up).
- Should not depend on anything outside the package directory other than
  a working `mex` toolchain (and any system tools like `cmake` if the
  package needs them).

### Minimal MEX example

```matlab
% compile.m — runs with cwd set to the package source root
fprintf('=== Compiling my_package MEX files ===\n');

mexDir = fullfile(pwd, 'src');
mex('-largeArrayDims', ...
    fullfile(mexDir, 'fast_thing.c'), ...
    '-outdir', mexDir);

fprintf('=== my_package MEX compilation complete ===\n');
```

### Patterns from existing packages

- Simple single-file MEX —
  [TFOCS/compile.m](packages/TFOCS/releases/1.4.1/compile.m).
- Many MEX files with BLAS/LAPACK linking —
  [manopt/compile.m](packages/manopt/releases/8.0/compile.m).
- Glob a directory and compile every `.cpp` with C++14 flags —
  [kdtree/compile.m](../mip-core/packages/kdtree/releases/master/compile.m).
- CMake-driven build of a vendored C++ library before the MEX link —
  [finufft/compile.m](../mip-core/packages/finufft/releases/2.5.0/compile.m).

### Static linking (required)

**Ship statically linked MEX binaries.** `.mhl` archives are loaded on
arbitrary end-user machines where matching versions of Boost, CGAL,
Eigen, libstdc++ etc. are not guaranteed to be present or
ABI-compatible. Dynamic third-party deps cause "works on the builder,
fails on the user" breakage. Only OS-provided libraries (libc,
libpthread, libm on Linux; libSystem, libc++ on macOS; ucrtbase,
MSVCP140 on Windows) should remain dynamic.

Platform guidance:

- **Linux.** Link libstdc++ and libgcc statically.
  - Plain `mex` call:
    `LDFLAGS=$LDFLAGS -static-libstdc++ -static-libgcc`.
  - CMake-driven build: pass
    `-DCMAKE_SHARED_LINKER_FLAGS="-static-libstdc++ -static-libgcc"`
    and the same for `CMAKE_MODULE_LINKER_FLAGS`. (MEX files built with
    `add_library(... SHARED ...)` pick up shared linker flags; modules
    use module linker flags — set both to be safe.)
  - vcpkg's default `x64-linux` triplet builds static third-party libs
    already.
- **macOS.** Apple Clang does not support `-static-libstdc++` (and
  doesn't need it — `libc++` is part of the OS). vcpkg's default
  `x64-osx` / `arm64-osx` triplets build static third-party libs, so no
  extra flags are needed for a CMake+vcpkg build. For Apple Silicon,
  pass `-DCMAKE_OSX_ARCHITECTURES=arm64` and
  `-DMatlab_MEX_EXTENSION=mexmaca64` so libigl-style CMake finds MATLAB
  correctly.
- **Windows.** The MEX file itself **must** link the dynamic MSVC
  runtime (`/MD`) to match MATLAB's ABI, but third-party deps should be
  statically bundled. With vcpkg, use the `x64-windows-static-md`
  triplet (static deps, dynamic runtime):
  `-DVCPKG_TARGET_TRIPLET=x64-windows-static-md`. Also pass
  `-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL` and
  `-DCMAKE_POLICY_DEFAULT_CMP0091=NEW` to force `/MD` consistently.

Verify the result on a fresh machine or with `ldd` (Linux) / `otool -L`
(macOS) / `dumpbin /dependents` (Windows) — the dependency list should
only contain OS-provided libraries.

### Trimming for GitHub-runner budgets

Bundles are built in CI on GitHub-hosted runners (~14 GB disk, 6 h
timeout per job). CMake+vcpkg stacks that pull in heavy dependencies
(CGAL, Embree, Boost, GMP, MPFR, El Topo, etc.) often blow past either
limit. When that happens, **disable the heavy optional features** via
CMake flags rather than dropping the whole MEX layer. For example,
gptoolbox disables CGAL/Embree/El Topo/XML through `-DLIBIGL_* =OFF`
flags in its `compile.m`, which sheds ~18 MEX files but lets the other
~31 ship cleanly.

Any time you disable features in `compile.m`, document what is no
longer available in the package's `README.md` (see Step 7).

### Other tips

- Use `ispc`, `ismac`, `isunix`, and `computer('arch')` to switch
  per-platform compiler flags.
- `error()` on any failure — the bundle pipeline aborts on a non-empty
  error, which is what you want.
- When shelling out to CMake/Make, pass `-j$(maxNumCompThreads)` so the
  runner's cores are actually used.
- **Clear `LD_LIBRARY_PATH` before `system()` calls on Linux.** MATLAB
  injects its own `libcurl.so.4` / `libssl` into `LD_LIBRARY_PATH`, and
  they are older/ABI-incompatible with what system tools expect. A
  subprocess `curl` (e.g. the one vcpkg uses to bootstrap itself) dies
  with `symbol lookup error: undefined symbol: curl_global_trace`. At
  the top of `compile.m`:

  ```matlab
  if isunix && ~ismac
      origLdPath = getenv('LD_LIBRARY_PATH');
      setenv('LD_LIBRARY_PATH', '');
      restoreLdPath = onCleanup(@() setenv('LD_LIBRARY_PATH', origLdPath));
  end
  ```

  `onCleanup` restores the path when the caller (`run_compile`) exits.
  CMake/GCC don't need MATLAB on `LD_LIBRARY_PATH` at compile/link
  time — `Matlab_ROOT_DIR` is enough.

---

## Step 6 — Write `test_<package_name>.m`

The test script is run by `mip test <package_name>` after the package is
loaded. It should:

- Use only the public API of the package (it runs after `mip load`).
- `assert(...)` on each invariant that should hold.
- `fprintf('SUCCESS\n')` at the very end so a successful run is obvious.
- Be deterministic — call `rng('default')` if any randomness is involved.

### Skeleton

```matlab
% Test script for my_package.

rng('default');

%% Test some_function
fprintf('Testing some_function...\n');
out = some_function(1, 2);
assert(abs(out - 3) < 1e-12, ...
    sprintf('some_function returned %g, expected 3', out));

fprintf('SUCCESS\n');
```

See [chunkie/test_chunkie.m](../mip-core/packages/chunkie/releases/master/test_chunkie.m)
and [kdtree/test_kdtree.m](../mip-core/packages/kdtree/releases/master/test_kdtree.m)
for fuller examples.

> **Note on `+namespace` functions.** `exist('pkg.fcn', 'file')` returns
> `0` for functions inside a `+pkg` folder in many MATLAB versions — it
> only matches loose `.m` files on the path. To assert that a namespaced
> function ships, check the file on disk (e.g.
> `isfile(fullfile(pkgRoot, '+pkg', 'fcn.m'))`) or use
> `~isempty(which('pkg.fcn'))`.

### Two test scripts when you have a MEX build + `[any]` fallback

If `mip.yaml` has both an architecture-specific MEX build and an
`[any]` fallback entry (the pattern in Step 4's common patterns), ship
**two** test scripts and wire each build entry to its own
`test_script:`:

- `test_<package_name>_mex.m` — exercises both the pure-MATLAB layer
  **and** at least one compiled MEX function. This catches broken
  builds, missing symbols, ABI mismatches, and disabled-feature
  regressions at `mip test` time rather than in user code.
- `test_<package_name>.m` — exercises only the pure-MATLAB layer. Used
  by the `[any]` fallback build on architectures where MEX is
  unavailable.

A MEX function call that returns a simple deterministic value (think
`fast_sparse` vs `sparse`, a predicate like `orient2d`, or a closed-form
geometric result) is ideal for the MEX test — quick, doesn't depend on
external data, fails loudly if the binary is broken.

---

## Step 7 — `README.md` and `example.m`

A `README.md` in the release directory is **required whenever the
bundled package differs from the upstream source in ways a user might
notice**: MEX features disabled to fit the CI budget, sub-toolboxes
removed via `remove_dirs`, license chosen from a dual-license upstream,
architectures where MEX binaries aren't produced, etc. A user who
downloads the `.mhl` and finds that a function they expected is missing
or non-functional should be able to learn why from this README.

At minimum, document:

- What the package does (one paragraph).
- Author, license, version, upstream repository.
- How to install and load via `mip` (copy-paste block).
- **What is shipped.** Which subdirectories / modules are on the MATLAB
  path after `mip load`.
- **What is not shipped**, if anything. Removed sub-toolboxes, MEX
  functions disabled because their upstream dependency (CGAL, Embree,
  etc.) is too heavy for CI, and a pointer to upstream's build
  instructions for users who need those pieces.
- **Static linking / architecture matrix**, if the package has a MEX
  build. Which architectures get pre-compiled binaries, and the fact
  that the binaries are statically linked against third-party deps.
- **Tests.** Which `test_<...>.m` scripts are shipped and roughly what
  each exercises.

See [manopt/README.md](packages/manopt/releases/8.0/README.md) for a
small example and
[gptoolbox/README.md](packages/gptoolbox/releases/master/README.md) for
a more detailed one covering trimmed features, static linking, and a
per-build test split.

An `example.m` shows a minimal end-to-end usage. By convention it begins
with the install/load line so a user can copy-paste it directly:

```matlab
mip load --channel mip-org/staging my_package --install

% ... example body ...
```

See [manopt/example.m](packages/manopt/releases/8.0/example.m).

---

## Step 8 — Verify locally (optional but recommended)

The prepare script uses the `requests` Python module; install it once
with `pip install requests` if it is not already on your system.

To validate your `recipe.yaml` and `mip.yaml` without actually
cloning/copying anything, run:

```bash
python3 scripts/prepare_packages.py --package <package_name> --dry-run
```

A successful dry-run prints `[DRY RUN] Would prepare <name>` but does
**not** produce the `build/prepared/` directory. To actually materialize
the prepared tree so you can bundle it, drop the `--dry-run` flag:

```bash
python3 scripts/prepare_packages.py --package <package_name>
```

Then, in MATLAB, point at the prepared directory and bundle:

```matlab
mip.bundle('build/prepared/<package_name>-<version>')
```

If the bundle succeeds and produces a `.mhl` plus `.mhl.mip.json` in
`build/bundled/`, the package is ready to push.

---

## Step 9 — Hand off for commit and push

When you (the assistant working on this channel) are done writing the
new files under `packages/<package_name>/releases/<version>/`, **stop
there**. Do **not** run `git add`, `git commit`, or `git push` on the
user's behalf unless they explicitly ask for it in the current turn.

Summarize what you changed, point at the files, and let the user
inspect and commit themselves. They will push to `main` when they're
ready. Once they do, the CI workflow will prepare, bundle (running
`compile.m` on each target architecture), upload `.mhl` files as
Release assets, and refresh the channel index.

After the workflow completes, users can install with:

```matlab
mip install --channel mip-org/staging <package_name>
mip load <package_name>
mip test <package_name>      % if you provided a test_<package_name>.m
```
