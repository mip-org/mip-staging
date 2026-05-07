% Test script for disk-conformal-map.
% Builds a small disk-topology triangle mesh and runs disk_conformal_map.

rng('default');

%% Spoke-triangulated disk: 8 boundary vertices + 1 center, 8 triangles.
% Every boundary vertex has valence 2 (in two adjacent triangles); the
% center has valence 8. Small but numerically well-behaved.
N = 8;
theta = linspace(0, 2*pi, N+1);
theta(end) = [];
boundary = [cos(theta(:)), sin(theta(:)), zeros(N, 1)];
center = [0, 0, 0];
v = [boundary; center];                    % N+1 = 9 vertices
f = zeros(N, 3);
for k = 1:N
    nextK = mod(k, N) + 1;
    f(k, :) = [k, nextK, N + 1];
end

nv = size(v, 1);

fprintf('Testing disk_conformal_map on a 9-vertex spoke mesh...\n');
map = disk_conformal_map(v, f);

assert(size(map, 1) == nv, ...
    sprintf('map has %d rows, expected %d', size(map, 1), nv));
assert(size(map, 2) >= 2, ...
    sprintf('map has %d columns, expected >= 2', size(map, 2)));

% Every image point should lie inside the closed unit disk.
radii = sqrt(sum(map(:, 1:2).^2, 2));
assert(all(radii <= 1 + 1e-6), ...
    sprintf('max radius = %g, expected <= 1', max(radii)));

% The boundary loop (the first N vertices) must land on the unit circle.
boundaryRadii = radii(1:N);
assert(all(abs(boundaryRadii - 1) < 1e-6), ...
    sprintf('boundary radii in [%g, %g], expected all == 1', ...
        min(boundaryRadii), max(boundaryRadii)));

%% cotangent_laplacian: sparse nv x nv
fprintf('Testing cotangent_laplacian...\n');
L = cotangent_laplacian(v, f);
assert(issparse(L), 'cotangent_laplacian must return a sparse matrix');
assert(isequal(size(L), [nv nv]), ...
    sprintf('cotangent_laplacian size = %dx%d, expected %dx%d', ...
        size(L, 1), size(L, 2), nv, nv));

%% beltrami_coefficient on the identity mapping v -> v (nf entries)
fprintf('Testing beltrami_coefficient...\n');
mu = beltrami_coefficient(v, f, v);
assert(numel(mu) == size(f, 1), ...
    sprintf('beltrami_coefficient returned %d, expected %d', ...
        numel(mu), size(f, 1)));
assert(all(abs(mu) < 1e-8), ...
    'identity mapping must have zero Beltrami coefficient');

fprintf('SUCCESS\n');
