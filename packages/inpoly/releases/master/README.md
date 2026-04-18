# inpoly

Fast point(s)-in-polygon queries for MATLAB. `inpoly2` determines the
inside/outside status for a set of query vertices against a general
(non-convex, multiply-connected) polygonal region using a
crossing-number test accelerated by y-sorting and binary search.
Complexity scales like O((N+M)*log(N)) for N query points and M edges,
a significant improvement over the O(N*M) brute-force approach.

- Upstream: https://github.com/dengwirda/inpoly
- Author: Darren Engwirda
- Version: master (development tip)
- License: Custom (free for private, research, and institutional use;
  commercial distribution by arrangement with the author — see
  `LICENSE.md` in the upstream repository)

## What is shipped

After `mip load`, the repository root is on the MATLAB path. The
primary entry point is `inpoly2`. Supporting files:

| File | Purpose |
| --- | --- |
| `inpoly2.m` | Main point-in-polygon query function |
| `inpoly2_mat.m` | Pure-MATLAB crossing-number kernel |
| `polydemo.m` | Demo script (`polydemo(1)`, `polydemo(2)`, `polydemo(3)`) |
| `mesh-file/` | Mesh I/O utilities used by the demos (not on path) |
| `test-data/` | Sample mesh files used by the demos |

The Octave-specific `inpoly2_oct.cpp` ships but is unused under MATLAB.

## Install

```matlab
mip install --channel mip-org/staging inpoly
mip load inpoly
```

## Usage

```matlab
% Define a polygon (vertices + edges)
node = [0 0; 1 0; 1 1; 0 1];
edge = [1 2; 2 3; 3 4; 4 1];

% Query points
vert = [0.5 0.5; 2.0 2.0; 0.25 0.75];

% Test which points are inside
[stat, bnds] = inpoly2(vert, node, edge);
% stat = [true; false; true], bnds = [false; false; false]
```

## Tests

`test_inpoly.m` checks interior, exterior, and boundary classification
on a unit square, batch queries, and implicit edge connectivity.
