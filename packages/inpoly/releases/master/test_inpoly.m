% Test script for inpoly.

fprintf('Checking inpoly2 is on the path...\n');
assert(~isempty(which('inpoly2')), 'inpoly2 is not on the MATLAB path');

%% Test 1 — points inside a unit square
fprintf('Testing points inside a unit square...\n');
node = [0 0; 1 0; 1 1; 0 1];
edge = [1 2; 2 3; 3 4; 4 1];

% Interior point
vert = [0.5, 0.5];
[stat, bnds] = inpoly2(vert, node, edge);
assert(stat == true, 'Center of unit square should be inside');
assert(bnds == false, 'Center of unit square should not be on boundary');

%% Test 2 — point outside
fprintf('Testing point outside the polygon...\n');
vert = [2.0, 2.0];
[stat, bnds] = inpoly2(vert, node, edge);
assert(stat == false, 'Point (2,2) should be outside unit square');

%% Test 3 — point on boundary
fprintf('Testing point on the boundary...\n');
vert = [0.5, 0.0];
[stat, bnds] = inpoly2(vert, node, edge);
assert(stat == true, 'Boundary point should be flagged inside');
assert(bnds == true, 'Boundary point should be flagged on boundary');

%% Test 4 — batch query with mixed results
fprintf('Testing batch query...\n');
vert = [0.5 0.5; 2.0 2.0; 0.25 0.75; -1.0 -1.0];
[stat, bnds] = inpoly2(vert, node, edge);
assert(isequal(size(stat), [4 1]), 'Output should be 4x1');
assert(stat(1) == true,  'Point 1 should be inside');
assert(stat(2) == false, 'Point 2 should be outside');
assert(stat(3) == true,  'Point 3 should be inside');
assert(stat(4) == false, 'Point 4 should be outside');

%% Test 5 — implicit edges (omit edge argument)
fprintf('Testing implicit edge connectivity...\n');
vert = [0.5 0.5];
stat = inpoly2(vert, node);
assert(stat == true, 'Center should be inside with implicit edges');

fprintf('SUCCESS\n');
