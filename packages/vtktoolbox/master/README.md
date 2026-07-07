# vtkToolbox

A MEX interface to the [VTK](https://vtk.org) library for MATLAB. It provides
functions to read and write VTK files (`vtkRead`, `vtkWrite` — legacy `.vtk`,
XML `.vtp`/`.vtu`, plus `.ply`, `.stl`, `.obj`, `.off`) and to apply VTK
filters (cleaning, thresholding, contouring, subdivision, smoothing, boolean
operations, connectivity, hole filling, stream tracing, ...) to VTK datasets
represented as plain MATLAB structs.

- Author: Steffen Schuler, Institute of Biomedical Engineering, Karlsruhe
  Institute of Technology
- License: MPL-2.0 (the vendored `S2-Sampling-Toolbox` helper library by
  Anton Semechko is MIT)
- Upstream: <https://github.com/KIT-IBT/vtkToolbox> (branch-tracked: this
  package follows `master`)

## Install

```matlab
mip install --channel mip-org/staging vtktoolbox
mip load vtktoolbox
```

## What is shipped

`mip load vtktoolbox` puts `MATLAB/` (the `vtk*` MEX + wrappers and the
pure-MATLAB helpers such as `vtkCreateIcosphere`, `vtkToTriangulation`,
`vtkTrisurf`) and `MATLAB/S2-Sampling-Toolbox` (sphere sampling/meshing
helpers) on the path.

The 29 MEX functions are built from source against a minimal static
**VTK 9.5.2** (the 19 VTK modules the toolbox uses; no rendering). VTK and —
on Linux — libstdc++/libgcc are statically linked into each MEX, so no VTK
installation is needed on the target machine. Binaries are produced for
`linux_x86_64`, `macos_arm64` (Apple Clang), and `windows_x86_64` (MSVC).
There is no pure-MATLAB fallback: the toolbox is MEX-only by nature.

Because each MEX carries its own copy of the VTK code it uses, the installed
package is large (roughly 0.5 GB on disk; ~150 MB download).

## What is not shipped

- `vtkMmg3d`, `vtkLineOfBlock`, and `vtkPlaneCutter` MEX: not built by the
  upstream CMakeLists either (`vtkMmg3d` needs mmg/scotch and is commented
  out upstream; the other two are not wired into the build).
- A few pure-MATLAB helpers shell out to **optional external tools** that are
  not bundled and must be installed separately if you need them:
  `tetrahedralizeTriangleMesh` (gmsh), `tetrahedralizeTriangleMesh_tetgen`
  (tetgen), `remeshTriangleMesh` (Instant Meshes). They error with a clear
  message when the tool is missing.

## Tests

`test_vtktoolbox.m` runs functional checks (file-format roundtrips, contour
of a sphere, threshold, subdivision, boolean union, hole filling, electrode
alignment, stream tracing of a constant field, ...) and invokes every one of
the 29 shipped MEX, satisfying the channel's MEX-coverage gate.
