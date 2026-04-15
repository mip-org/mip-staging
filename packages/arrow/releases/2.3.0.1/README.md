# arrow

Draws annotated arrows on 2D or 3D MATLAB axes. Supports configurable
arrowhead length, base/tip angles, and base width, and lets you
retroactively update already-drawn arrows by handle.

- Upstream: https://www.mathworks.com/matlabcentral/fileexchange/278-arrow
- Author: Erik A Johnson
- Version: 2.3.0.1
- License: BSD-3-Clause

## Install

```matlab
mip install --channel mip-org/staging arrow
mip load arrow
```

## Usage

```matlab
% Simple 2D arrow
arrow([0 0], [1 1]);

% 3D arrow with a longer head
arrow([0 0 0], [1 2 3], 'Length', 12);

% Demo
arrow demo
```

Call `arrow properties` from the MATLAB prompt for the full property
reference.
