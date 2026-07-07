% Test script for vtktoolbox.
%
% Exercises every MEX the package ships (the CI coverage gate diffs the
% shipped .mex* files against MATLAB's inmem list, so each of the 29 MEX
% built by compile.m must be invoked here at least once).
rng('default');

tmpd = tempname;
mkdir(tmpd);
cleanupTmp = onCleanup(@() rmdir(tmpd, 's'));

% Unit icosphere via the vendored S2-Sampling-Toolbox (pure MATLAB):
% subdivision level 3 -> 642 points, 1280 triangles.
sph = vtkCreateIcosphere(3);
assert(size(sph.points, 1) == 642, 'icosphere has %d points', size(sph.points, 1));
assert(size(sph.cells, 1) == 1280, 'icosphere has %d cells', size(sph.cells, 1));

% ---- vtkWrite / vtkRead roundtrips (legacy vtk, XML vtp, PLY) ------------
fprintf('Testing vtkWrite/vtkRead...\n');
for fmt = {'vtk', 'vtp', 'ply'}
    f = fullfile(tmpd, ['sphere.' fmt{1}]);
    vtkWrite(sph, f);
    back = vtkRead(f);
    assert(size(back.points, 1) == size(sph.points, 1), '%s roundtrip lost points', fmt{1});
    assert(isequal(back.cells, sph.cells), '%s roundtrip changed cells', fmt{1});
    assert(max(abs(double(back.points(:)) - sph.points(:))) < 1e-6, ...
        '%s roundtrip changed coordinates', fmt{1});
end

% ---- point data <-> cell data --------------------------------------------
fprintf('Testing data mapping filters...\n');
sphD = sph;
sphD.pointData.z = sph.points(:, 3);

cd1 = vtkPointDataToCellData(sphD);
assert(isfield(cd1, 'cellData') && isfield(cd1.cellData, 'z'), ...
    'vtkPointDataToCellData did not produce cellData.z');
pd1 = vtkCellDataToPointData(cd1);
assert(isfield(pd1, 'pointData') && isfield(pd1.pointData, 'z'), ...
    'vtkCellDataToPointData did not produce pointData.z');

% ---- contour and threshold -----------------------------------------------
fprintf('Testing vtkContourFilter/vtkThreshold...\n');
% Isoline z = 0 on the unit sphere is the unit circle.
ct = vtkContourFilter(sphD, 'points', 'z', 0);
assert(size(ct.points, 1) > 0, 'contour is empty');
rxy = sqrt(sum(double(ct.points(:, 1:2)).^2, 2));
assert(all(abs(rxy - 1) < 0.05), 'contour points are not on the unit circle');
assert(all(abs(double(ct.points(:, 3))) < 1e-6), 'contour points are not at z=0');

% Threshold keeps the lower hemisphere; output is an unstructured grid.
th = vtkThreshold(sphD, 'points', 'z', [-2, 0]);
assert(size(th.points, 1) < size(sph.points, 1) && size(th.points, 1) > 0, ...
    'threshold did not reduce the point count');

sf = vtkDataSetSurfaceFilter(th);
assert(size(sf.cells, 1) == size(th.cells, 1), ...
    'surface filter changed the cell count of a triangle surface');

% ---- per-cell measures ----------------------------------------------------
fprintf('Testing vtkMeshQuality/vtkCellCentroids/vtkIntegrateAttributes...\n');
mq = vtkMeshQuality(sph);
assert(isfield(mq, 'cellData'), 'vtkMeshQuality returned no cellData');

cc = vtkCellCentroids(sph);
assert(size(cc.points, 1) == size(sph.cells, 1), ...
    'vtkCellCentroids point count does not match cell count');
rc = sqrt(sum(double(cc.points).^2, 2));
assert(all(rc < 1 & rc > 0.9), 'centroids are not just inside the unit sphere');

ia = vtkIntegrateAttributes(sph);
assert(isstruct(ia) && size(ia.points, 1) == 1, ...
    'vtkIntegrateAttributes did not reduce to a single point');

% ---- topology filters -----------------------------------------------------
fprintf('Testing topology filters...\n');
tf = vtkTriangleFilter(sph);
assert(size(tf.cells, 1) == size(sph.cells, 1), 'triangle filter changed a pure-tri mesh');

cp = vtkCleanPolyData(sph);
assert(size(cp.points, 1) == size(sph.points, 1), 'clean removed points from a clean mesh');

ee = vtkExtractEdges(sph);
% Closed triangulation: E = V + F - 2.
assert(size(ee.cells, 1) == 642 + 1280 - 2, 'unexpected edge count');

ls = vtkLinearSubdivisionFilter(sph, 1);
assert(size(ls.cells, 1) == 4 * size(sph.cells, 1), 'linear subdivision cell count');
lo = vtkLoopSubdivisionFilter(sph, 1);
assert(size(lo.cells, 1) == 4 * size(sph.cells, 1), 'loop subdivision cell count');

% ---- smoothing -------------------------------------------------------------
fprintf('Testing smoothing filters...\n');
sm = vtkSmoothPolyDataFilter(sph, 20);
assert(isequal(size(sm.points), size(sph.points)), 'laplacian smoothing changed layout');
ws = vtkWindowedSincPolyDataFilter(sph, 20, 0.1);
assert(isequal(size(ws.points), size(sph.points)), 'sinc smoothing changed layout');

% ---- open surfaces: feature edges, hole filling, extrusion ----------------
fprintf('Testing vtkFeatureEdges/vtkFillSurfaceHoles/vtkLinearExtrusionFilter...\n');
% Open hemisphere: keep cells whose centroid has z < 0.
ccz = (sph.points(sph.cells(:, 1), 3) + sph.points(sph.cells(:, 2), 3) ...
    + sph.points(sph.cells(:, 3), 3)) / 3;
hemi = sph;
hemi.cells = sph.cells(ccz < 0, :);
hemi.cellTypes = sph.cellTypes(ccz < 0);
hemi = vtkCleanPolyData(hemi);

fe = vtkFeatureEdges(hemi, true, false, false, false, false, 30);
assert(size(fe.points, 1) > 0, 'open hemisphere has no boundary edges');

fh = vtkFillSurfaceHoles(hemi, 'none');
assert(size(fh.cells, 1) > size(hemi.cells, 1), 'hole filling added no cells');

le = vtkLinearExtrusionFilter(hemi, [0 0 1], 0.5);
assert(size(le.points, 1) > size(hemi.points, 1), 'extrusion added no points');

% ---- append / connectivity / clean (unstructured grid) --------------------
fprintf('Testing append and connectivity filters...\n');
sphFar = vtkCreateIcosphere(3, 1, [3 0 0]);
ap = vtkAppendPolyData({sph, sphFar});
assert(size(ap.points, 1) == 2 * size(sph.points, 1), 'append polydata point count');

cf = vtkConnectivityFilter(ap);
assert(numel(unique(cf.pointData.RegionId)) == 2, ...
    'connectivity did not find 2 regions');

afDup = vtkAppendFilter({sph, sph}, false);
assert(size(afDup.points, 1) == 2 * size(sph.points, 1), 'append filter point count');
cu = vtkCleanUnstructuredGrid(afDup);
assert(size(cu.points, 1) == size(sph.points, 1), ...
    'clean unstructured grid did not merge duplicate points');

% ---- boolean operation -----------------------------------------------------
fprintf('Testing vtkBooleanOperationPolyDataFilter...\n');
sphOff = vtkCreateIcosphere(3, 1, [1 0 0]);
bo = vtkBooleanOperationPolyDataFilter(sph, sphOff, 'union');
assert(size(bo.points, 1) > 0, 'boolean union is empty');
assert(max(double(bo.points(:, 1))) > 1.5 && min(double(bo.points(:, 1))) < -0.5, ...
    'boolean union does not span both spheres');

% ---- mesh-to-mesh mapping ---------------------------------------------------
fprintf('Testing vtkArrayMapperNearestNeighbor/vtkBarycentricCoords...\n');
am = vtkArrayMapperNearestNeighbor(sphD, ls);
assert(isfield(am, 'pointData') && isfield(am.pointData, 'z'), ...
    'nearest-neighbor mapper did not map pointData.z');
assert(size(am.pointData.z, 1) == size(ls.points, 1), 'mapped array has wrong length');

% Barycentric coords of a slightly smaller sphere's points projected along
% their normals onto the unit sphere. Rotate the target so its vertex rays
% don't pass exactly through source mesh vertices (both spheres are
% icosahedral, and vertex-grazing rays are missed by the OBB line search).
sphSmall = vtkCreateIcosphere(2, 0.95);
ax = [1; 2; 3] / norm([1; 2; 3]);
K = [0 -ax(3) ax(2); ax(3) 0 -ax(1); -ax(2) ax(1) 0];
R = eye(3) + sin(0.15) * K + (1 - cos(0.15)) * (K * K);
sphSmall.points = sphSmall.points * R';
[cellIds, baryCoords] = vtkBarycentricCoords(sph, sphSmall, 1);
assert(size(baryCoords, 1) == size(sphSmall.points, 1), 'barycentric coords count');
assert(all(abs(sum(baryCoords, 2) - 1) < 1e-6), 'barycentric coords do not sum to 1');
assert(all(cellIds >= 1), 'source cell ids are not 1-based');

% ---- electrode alignment ----------------------------------------------------
fprintf('Testing vtkAlignNodesWithElectrodes...\n');
% The MEX projects each electrode onto the body surface along the normal of
% the nearest node, using a fixed +/-20 length-unit search ray (it assumes
% mm-scale meshes), and moves that node to the projection. Use a radius-50
% sphere so the ray only reaches the near side, and put electrodes above
% cell centroids so the projections land clearly away from existing nodes.
sphBig = vtkCreateIcosphere(3, 50);
edirs = zeros(3);
for k = 1:3
    tri = sphBig.cells(400 * k - 399, :);   % cells 1, 401, 801: well separated
    cdir = mean(sphBig.points(tri, :), 1);
    edirs(k, :) = cdir / norm(cdir);
end
electrodes = vtkCreateStruct(52 * edirs);
an = vtkAlignNodesWithElectrodes(sphBig, electrodes);
assert(isequal(size(an.points), size(sphBig.points)), 'alignment changed the mesh layout');
dmoved = sqrt(sum((double(an.points) - sphBig.points).^2, 2));
moved = find(dmoved > 1e-9);
assert(numel(moved) == 3, 'expected 3 moved nodes, got %d', numel(moved));
for k = 1:3
    % The node moved for electrode k must sit on the electrode's radial ray
    % (near side) and on the surface.
    mpts = double(an.points(moved, :));
    proj = mpts * edirs(k, :)';
    perp = sqrt(max(sum(mpts.^2, 2) - proj.^2, 0));
    [pmin, j] = min(perp);
    assert(pmin < 1 && proj(j) > 0, 'electrode %d: no moved node on its ray', k);
    assert(abs(norm(mpts(j, :)) - 50) < 1, 'electrode %d: moved node is off the surface', k);
end

% ---- stream tracer -----------------------------------------------------------
fprintf('Testing vtkStreamTracer...\n');
% Tet-mesh a unit cube lattice and trace a constant [1 0 0] velocity field.
[X, Y, Z] = ndgrid(0:0.25:1);
pts = [X(:), Y(:), Z(:)];
dt = delaunayTriangulation(pts);
grid3 = vtkCreateStruct(pts, dt.ConnectivityList);
grid3.pointData.vel = repmat([1 0 0], size(pts, 1), 1);
seeds = vtkCreateStruct([0.05 0.5 0.5]);
st = vtkStreamTracer(grid3, 'points', 'vel', seeds, 'forward', 0.05);
assert(size(st.points, 1) > 2, 'streamline has too few points');
assert(max(double(st.points(:, 1))) > 0.9, 'streamline did not cross the cube');
assert(all(abs(double(st.points(:, 2)) - 0.5) < 1e-6), 'streamline drifted in y');

fprintf('SUCCESS\n');
