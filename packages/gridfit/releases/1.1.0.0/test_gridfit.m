% Test script for gridfit.

rng('default');

fprintf('Checking gridfit is on the path...\n');
assert(~isempty(which('gridfit')), 'gridfit is not on the MATLAB path');

fprintf('Fitting a plane z = 2x + 3y from scattered samples...\n');
N = 400;
x = rand(N, 1) * 10;
y = rand(N, 1) * 10;
z = 2 * x + 3 * y + 0.01 * randn(N, 1);

xnodes = linspace(0, 10, 21);
ynodes = linspace(0, 10, 21);
[zgrid, xgrid, ygrid] = gridfit(x, y, z, xnodes, ynodes, 'smoothness', 1);

fprintf('Checking output shape...\n');
assert(isequal(size(zgrid), [numel(ynodes), numel(xnodes)]), ...
    sprintf('zgrid has unexpected shape %dx%d', size(zgrid, 1), size(zgrid, 2)));
assert(isequal(size(xgrid), size(zgrid)), 'xgrid shape mismatch');
assert(isequal(size(ygrid), size(zgrid)), 'ygrid shape mismatch');

fprintf('Checking the fit recovers the plane to within tolerance...\n');
expected = 2 * xgrid + 3 * ygrid;
err = max(abs(zgrid(:) - expected(:)));
assert(err < 0.1, sprintf('Max fit error %g exceeds tolerance', err));

fprintf('SUCCESS\n');
