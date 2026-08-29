# robotics-toolbox-matlab

Robotics Toolbox for MATLAB (RTB) by Peter Corke. Provides
serial-link robot kinematics and dynamics (forward/inverse
kinematics, Jacobians, recursive Newton-Euler, inertia/coriolis
matrices, trajectory generation), mobile-robot navigation (Bug2,
D*, RRT, Dubins, Reeds-Shepp, lattice, PRM), vehicle models and
drivers (`Vehicle`, `Bicycle`, `Unicycle`), Extended Kalman filter
and particle filter localization, and several quadrotor / mobile
robot Simulink models. Ships with ready-to-use models for Puma
560, Stanford arm, Baxter, UR3/5/10, Kuka LBR, ABB IRB series,
and many more.

- Upstream: https://github.com/petercorke/robotics-toolbox-matlab
- Author: Peter Corke
- Version: 10.4 (upstream tag `10.4`)
- License: GNU Lesser General Public License v3 or later (LGPL-3.0-or-later)

## Dependency

RTB depends on the Spatial Math Toolbox (`spatialmath-matlab`) for
its pose-representation classes (`SE3`, `SO3`, `Twist`,
`UnitQuaternion`, etc.) and rotation utilities (`rotx`, `transl`,
`trotx`, ...). `mip load robotics-toolbox-matlab` loads
`spatialmath-matlab` first.

## What is shipped

After `mip load robotics-toolbox-matlab`, these are on the path by
default:

| Path | Contents |
| --- | --- |
| `.` (root) | Core classes and functions: `SerialLink`, `Link`, `Bicycle`, `EKF`, `ParticleFilter`, planners (`Bug2`, `Dstar`, `RRT`, `ReedsShepp`, ...), etc. |
| `mex/` | `frne.c` sources plus (on supported architectures) the compiled `frne` MEX file |
| `models/` | `mdl_puma560`, `mdl_baxter`, `mdl_ur5`, and dozens of other pre-built robot models |
| `data/` | Robot mesh files, road/house maps, and other demo data |
| `Apps/` | MATLAB apps shipped with the toolbox |

Optional trees gated behind `mip load --with <group>`:

- `--with examples` → `demos/` and `examples/` (end-user demo scripts).
- `--with simulink` → `simulink/` (Simulink models for a non-holonomic vehicle and a quadrotor).
- `--with vrep` → `interfaces/VREP/` (V-REP / CoppeliaSim bridge).
- `--with tests` → `test/` (upstream unit tests).

The `doc/` directory (61 MB of pre-rendered HTML + PDF) is dropped
from the bundle.

### Java bits

The `java/` directory ships the source for the DH-factorization
Java helper but does **not** ship `DHFactor.jar` — upstream builds
that jar out-of-band, and it isn't included in the repository.
`DHFactor()` will therefore not work unless you separately build
and drop `java/DHFactor.jar` in place. All non-Java functionality
is unaffected.

## Architecture matrix

| Architecture | frne MEX shipped | rne() backend |
| --- | --- | --- |
| `linux_x86_64` | yes | compiled MEX (fast) |
| `macos_x86_64` | yes | compiled MEX (fast) |
| `macos_arm64` | yes | compiled MEX (fast) |
| `windows_x86_64` | yes | compiled MEX (fast) |
| anything else | no | pure-MATLAB `rne_dh` / `rne_mdh` fallback |

`SerialLink` auto-detects the `frne` MEX at construction time
(`exist('frne') == 3`) and sets the `.fast` flag accordingly. All
public entry points keep working in either mode; the difference is
speed.

On Linux the MEX file links `libstdc++` / `libgcc` statically so
it loads on end-user machines without matching the builder's C++
runtime.

## Install

```matlab
mip install --channel mip-org/staging robotics-toolbox-matlab
mip load robotics-toolbox-matlab
```

## Tests

Two test scripts are shipped, one per build entry:

- `test_rtb_mex.m` (architecture-specific builds) — loads Puma
  560, checks forward/inverse kinematics, runs `jtraj`, and
  verifies that `frne` is detected and `rne()` produces a finite
  6-vector.
- `test_rtb.m` (`[any]` fallback) — same kinematics checks but
  without the MEX-present assertion.
