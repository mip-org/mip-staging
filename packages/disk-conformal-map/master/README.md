# disk-conformal-map

Fast disk conformal parameterization — angle-preserving mapping of
a simply-connected open triangle mesh onto the unit disk. Useful
for texture mapping, surface registration, and mechanical
engineering applications. Primary entry point:

```matlab
map = disk_conformal_map(v, f)
```

where `v` is `nv x 3` vertex coordinates and `f` is `nf x 3`
triangulation. Preconditions: the mesh must be simply connected
and open (have a boundary), free of unreferenced / non-manifold
vertices / non-manifold edges, and every boundary vertex must have
valence ≥ 2 (strip valence-1 leaves first).

- Upstream: https://github.com/garyptchoi/disk-conformal-map
- Author: Gary Pui-Tung Choi
- Version: master (development tip — no tagged releases upstream)
- License: Apache-2.0
- References:
  - Choi & Lui, "Fast Disk Conformal Parameterization of
    Simply-Connected Open Surfaces," *J. Sci. Comput.* 65(3),
    1065–1090 (2015).
  - Choi, Leung-Liu, Gu & Lui, "Parallelizable global conformal
    parameterization of simply-connected surfaces via partial
    welding," *SIAM J. Imaging Sci.* 13(3), 1049–1083 (2020)
    — covers `mobius_area_correction_disk`.

## What is shipped

After `mip load disk-conformal-map`, `mfile/` and `extension/`
are on the MATLAB path:

| Path | Contents |
| --- | --- |
| `mfile/` | Core: `disk_conformal_map`, `tutte_map`, `cotangent_laplacian`, `generalized_laplacian`, `linear_beltrami_solver`, `beltrami_coefficient`, `angle_distortion`, `f2v`, `plot_mesh` |
| `extension/` | Optional: `mobius_area_correction_disk`, `remeshing`, `area_distortion`, `face_area` |

The repository root — four sample `.mat` meshes
(`human_face.mat`, `chinese_lion.mat`, `human_brain.mat`,
`hand.mat`) plus the upstream demo scripts (`demo.m`,
`demo_extension.m`, `demo_remeshing.m`) — is **not** on the
default path. Opt in with:

```matlab
mip load disk-conformal-map --with examples
demo       % runs the four-example tour
```

## Install

```matlab
mip install --channel mip-org/staging disk-conformal-map
mip load disk-conformal-map
```

## Tests

`test_disk_conformal_map.m` builds a 5-vertex open mesh
(center + 4 corners, 4 triangles), runs `disk_conformal_map`, and
verifies that every image point lies inside the closed unit disk
and that the four boundary vertices land exactly on the unit
circle. It also exercises `cotangent_laplacian` and
`beltrami_coefficient` on the same mesh.
