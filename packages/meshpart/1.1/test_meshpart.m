% Test script for meshpart.

rng('default');

%% grid5: 4x4 5-point grid -> 16 nodes, symmetric structure
fprintf('Testing grid5...\n');
[A, xy] = grid5(4);
assert(size(A, 1) == 16 && size(A, 2) == 16, ...
    sprintf('grid5(4) produced %dx%d matrix, expected 16x16', size(A,1), size(A,2)));
assert(isequal(A, A'), 'grid5 matrix must be symmetric');
assert(size(xy, 1) == 16 && size(xy, 2) == 2, ...
    'grid5 xy must be 16x2');

%% specpart: splits the 16 vertices into two disjoint non-empty halves
fprintf('Testing specpart...\n');
[part1, part2] = specpart(A);
assert(~isempty(part1) && ~isempty(part2), 'specpart returned empty half');
assert(numel(part1) + numel(part2) == 16, ...
    sprintf('specpart halves sum to %d, expected 16', ...
        numel(part1) + numel(part2)));
assert(isequal(sort([part1(:); part2(:)]), (1:16)'), ...
    'specpart halves must partition 1:16');

%% cutsize: returns a positive integer for a non-trivial partition
fprintf('Testing cutsize...\n');
ne = cutsize(A, part1, part2);
assert(isscalar(ne) && ne > 0 && ne == round(ne), ...
    sprintf('cutsize returned %g, expected a positive integer', ne));

%% fiedler: returns a vector of length n
fprintf('Testing fiedler...\n');
x = fiedler(A);
assert(numel(x) == 16, ...
    sprintf('fiedler returned %d entries, expected 16', numel(x)));

%% gridt: k=4 triangular mesh has k*(k+1)/2 = 10 nodes
fprintf('Testing gridt...\n');
[At, xyt] = gridt(4);
assert(size(At, 1) == 10, ...
    sprintf('gridt(4) produced %d nodes, expected 10', size(At, 1)));
assert(size(xyt, 1) == 10 && size(xyt, 2) == 2, ...
    'gridt xy must be 10x2');

%% inertpart: inertial bisection partitions all 10 vertices
fprintf('Testing inertpart...\n');
[ip1, ip2] = inertpart(At, xyt);
assert(numel(ip1) + numel(ip2) == 10, ...
    sprintf('inertpart halves sum to %d, expected 10', ...
        numel(ip1) + numel(ip2)));
assert(isequal(sort([ip1(:); ip2(:)]), (1:10)'), ...
    'inertpart halves must partition 1:10');

%% vtxsep: vertex separator is a non-empty subset of 1:n
fprintf('Testing vtxsep...\n');
sep = vtxsep(A, part1);
assert(~isempty(sep), 'vtxsep returned empty separator');
assert(all(sep >= 1 & sep <= 16), ...
    'vtxsep entries out of range');

fprintf('SUCCESS\n');
