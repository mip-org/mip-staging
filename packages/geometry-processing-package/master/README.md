# geometry-processing-package

A MATLAB toolbox for triangle-mesh processing developed by the
Computational Geometry Group at the Chinese University of Hong Kong. It
covers basic mesh algebra (adjacency, edges, Laplace–Beltrami, face /
vertex areas), OBJ/OFF/PLY I/O, sparse-matrix format conversions, a few
parameterization maps (disk / rectangular harmonic, spherical conformal),
and topology utilities (boundary / homology / homotopy bases, cut graph,
Dijkstra, minimum spanning tree, mesh slicing).

- **Author**: Wen Cheng Feng, Computational Geometry Group, CUHK
- **License**: MIT
- **Version**: tracks upstream `master` (repository has no tagged releases)
- **Repository**: https://github.com/cfwen/geometry-processing-package

## Install

```matlab
mip install --channel mip-org/staging geometry-processing-package
mip load geometry-processing-package
```

Pure MATLAB — no compilation, works on any architecture.

## What is shipped

After `mip load`, the following directories are on the path:

- `algebra/` — `compute_adjacency_matrix`, `compute_edge`,
  `compute_bd`, `compute_halfedge`, `face_area`, `vertex_area`,
  `laplace_beltrami`, `generalized_laplacian`, etc.
- `graphics/` — `plot_mesh`, `plot_path`.
- `io/` — `read_obj` / `write_obj`, `read_off` / `write_off`,
  `read_ply` / `write_ply`.
- `misc/` — `sparse_to_csc`, `sparse_to_csr`, and their inverses.
- `parameterization/` — `disk_harmonic_map`, `rect_harmonic_map`,
  `spherical_conformal_map`.
- `topology/` — `clean_mesh`, `compute_greedy_homotopy_basis`,
  `compute_homology_basis`, `cut_graph`, `dijkstra`,
  `minimum_spanning_tree`, `slice_mesh`, `remove_mesh_face`,
  `remove_mesh_vertex`.

The `tutorial/` directory (three walk-through scripts) is bundled but
**not** on the default path. Opt in with:

```matlab
mip load geometry-processing-package --with examples
```

Sample meshes in `data/` (bunny, kitten, face, torus, sphere, etc.) are
bundled and referenced by the tutorials via relative paths — `cd` to the
package root before running them.

## Tests

`test_geometry_processing_package.m` exercises `face_area`,
`compute_edge`, `compute_bd`, `vertex_area`, `laplace_beltrami`,
`compute_adjacency_matrix`, and an `write_off` / `read_off` roundtrip on
a two-triangle unit square. Run it with:

```matlab
mip test geometry-processing-package
```
