# spatialmath-matlab

Spatial Math Toolbox for MATLAB — functions and classes for
representing orientation and pose in 2D and 3D: SO(2)/SE(2) for
planar, SO(3)/SE(3) for spatial rotations and rigid-body
transforms, plus unit quaternions, twists, triple angles, and
graphical display utilities. Much of this code was previously
distributed as part of the Robotics Toolbox for MATLAB; it was
split out in 2019 to be useful as a standalone dependency.

- Upstream: https://github.com/petercorke/spatialmath-matlab
- Author: Peter Corke
- Version: master (development tip — no tagged releases upstream)
- License: MIT

## What is shipped

After `mip load spatialmath-matlab`, the repository root is on the
MATLAB path. That covers every `.m` file at the top level
(rotation/transform utilities like `rotx`, `trotx`, `transl`,
`r2t`, `t2r`, `rpy2r`, `angvec2r`; class files `SE3.m`, `SO3.m`,
`SE2.m`, `SO2.m`, `Twist.m`, `Twist2.m`, `Quaternion.m`,
`UnitQuaternion.m`, `Plucker.m`, `PGraph.m`; and the
`plot_*`/`trplot*`/`tranimate` visualization helpers).

The `unit_test/` directory with the upstream test suite is **not**
on the default path. Opt in with
`mip load spatialmath-matlab --with tests`.

The `doc/` directory (12 MB of pre-rendered HTML and figures) is
dropped from the bundle.

## Install

```matlab
mip install --channel mip-org/staging spatialmath-matlab
mip load spatialmath-matlab
```

## Usage

```matlab
% 3D rotation about the x axis
R = rotx(pi/2);

% 4x4 homogeneous transform: translate then rotate
T = transl(1, 2, 3) * trotx(pi/4);

% SE3 class
pose = SE3(1, 2, 3) * SE3.Rx(pi/4);
pose.plot()

% Unit quaternion from a rotation matrix
q = UnitQuaternion(R);
```

## Tests

`test_spatialmath.m` exercises `rotx`/`roty`/`rotz`, `transl`,
`trotx`, `r2t`/`t2r`, the `SE3`/`SO3` classes, and
`UnitQuaternion` roundtrip conversion.
