# meshpart

MATLAB toolbox for graph and mesh partitioning: spectral
(`specpart`), geometric (`geopart`), geometric-spectral (`gspart`),
coordinate (`coordpart`), and inertial (`inertpart`) bisection;
recursive multiway partitions (`dice`, `geodice`, `specdice`,
`gsdice`); vertex separators (`vtxsep`, `geosep`, `specsep`); and
nested dissection orderings (`ndperm`, `geond`, `specnd`, `gsnd`).
Ships with sample meshes (Eppstein, Smallmesh, Tapir) and grid
generators (`grid5`, `grid7`, `grid9`, `gridt`, `grid3d`, `grid3dt`).

- Upstream: https://github.com/YingzhouLi/meshpart
- Authors: John R. Gilbert (UCSB), Shang-Hua Teng (USC),
  Yingzhou Li (Fudan). Tim Davis updated the toolbox for MATLAB 5.
- Version: 1.1 (upstream tag `v1.1`)
- License: Dual MIT + Xerox research-and-evaluation
  (`LicenseRef-Meshpart`). The modern code is MIT-licensed
  (Copyright 2017 Yingzhou Li, Gilbert, and Teng). Portions derived
  from the original Xerox PARC distribution (Copyright 1990-2002
  Xerox / Gilbert / Teng) retain the Xerox license, which grants
  permission to copy, use, and make derivative works
  **"for research and evaluation purposes"** only. Commercial use
  of those portions is not authorized. See `LICENSE` in the
  upstream repository for the full text.

## What is shipped

After `mip load meshpart`, the `src/` tree is on the MATLAB path
(including `src/grid/`, `src/util/`, and `src/vis/` subdirectories).

| Subdirectory | Functions |
| --- | --- |
| `src/` | Core partitioners and dicing: `specpart`, `geopart`, `gspart`, `coordpart`, `inertpart`, `dice`, `geodice`, `specdice`, `gsdice`, `specnd`, `geond`, `gsnd`, `ndperm`, `vtxsep`, `geosep`, `specsep`, `ganalyze` |
| `src/grid/` | Mesh generators: `grid5`, `grid7`, `grid9`, `gridt`, `grid3d`, `grid3dt`, `badmesh`, `cockroach`, `treexpath`, `tree3xpath`, `book` |
| `src/util/` | Support: `fiedler`, `cutsize`, `contract`, `blockdiags`, `centerpoint`, `partition`, `sepcircle`, `sepline`, `sepquality`, `reflector`, `stereoup`, `stereodown`, `maxel`, `conmap`, `conmapinv`, `radong`, `mscircle` |
| `src/vis/` | Plotting: `gplotg`, `gplotmap`, `gplotpart`, `ghighlight` |

The `test/` directory (interactive demos `meshdemo`, `geopartdemo`,
and `meshes.mat` containing the Eppstein/Smallmesh/Tapir sample
meshes) is **not** on the default path. Opt in with:

```matlab
mip load meshpart --with examples
meshdemo       % runs the four built-in demos
```

## Install

```matlab
mip install --channel mip-org/staging meshpart
mip load meshpart
```

## Usage

```matlab
% Generate a 16-node 5-point grid and spectrally bisect it
[A, xy] = grid5(4);
[part1, part2] = specpart(A);
gplotpart(A, xy, part1);
```

## Upstream dependencies

The geometric partitioners (`geopart`, `gspart`, `geodice`, `gsdice`,
`geond`, `gsnd`, `geosep`) call `centerpoint`, which uses
`randsample` from the **Statistics and Machine Learning Toolbox**.
Without that toolbox, those routines will error. The spectral
(`specpart`, `specdice`, `specnd`, `specsep`), coordinate-axis, and
inertial (`inertpart`) partitioners, as well as every routine under
`src/util/`, `src/grid/`, and `src/vis/`, only use base MATLAB.

## Tests

`test_meshpart.m` exercises the public API on a small grid:
`grid5`, `specpart`, `cutsize`, `fiedler`, `gridt`, `inertpart`, and
`vtxsep`. Run with `mip test meshpart`. The test avoids
`geopart`/`gspart` so the toolbox dependency above is not required.
