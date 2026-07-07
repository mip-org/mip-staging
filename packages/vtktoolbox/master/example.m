mip install --channel mip-org/staging vtktoolbox
mip load vtktoolbox

% Create a unit icosphere and attach the z-coordinate as point data.
sphere = vtkCreateIcosphere(3);
sphere.pointData.z = sphere.points(:, 3);

% Extract the isoline z = 0 (the equator).
equator = vtkContourFilter(sphere, 'points', 'z', 0);
fprintf('Equator has %d points.\n', size(equator.points, 1));

% Keep the lower hemisphere and take its surface.
lower = vtkThreshold(sphere, 'points', 'z', [-1, 0]);
surface = vtkDataSetSurfaceFilter(lower);

% Smooth it and write it to a VTP file (also try .vtk, .ply, .stl, .obj).
smoothed = vtkWindowedSincPolyDataFilter(surface, 20, 0.1);
vtkWrite(smoothed, 'lower_hemisphere.vtp');

% Read it back and plot.
mesh = vtkRead('lower_hemisphere.vtp');
vtkTrisurf(mesh);
