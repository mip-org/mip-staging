% Test script for geometry-processing-package.

rng('default');

% Unit square made of two triangles in the z=0 plane.
vertex = [0 0 0; 1 0 0; 1 1 0; 0 1 0];
face = [1 2 3; 1 3 4];

%% face_area: two right triangles of area 1/2
fprintf('Testing face_area...\n');
fa = face_area(face, vertex);
assert(numel(fa) == 2 && abs(sum(fa) - 1) < 1e-12, ...
    sprintf('face_area sum = %g, expected 1', sum(fa)));

%% compute_edge: 5 undirected edges (4 boundary + 1 diagonal)
fprintf('Testing compute_edge...\n');
[edge, ~] = compute_edge(face);
assert(size(edge, 1) == 5, ...
    sprintf('compute_edge returned %d edges, expected 5', size(edge, 1)));

%% compute_halfedge: 6 halfedges for 2 triangles
fprintf('Testing compute_halfedge...\n');
[he, heif] = compute_halfedge(face);
assert(size(he, 1) == 6, ...
    sprintf('compute_halfedge returned %d halfedges, expected 6', size(he, 1)));
assert(numel(heif) == 6, ...
    sprintf('compute_halfedge heif has %d entries, expected 6', numel(heif)));

%% vertex_area ('mixed'): Voronoi-style partition of total mesh area
fprintf('Testing vertex_area...\n');
va = vertex_area(face, vertex, 'mixed');
assert(numel(va) == 4 && abs(sum(va) - 1) < 1e-12, ...
    sprintf('vertex_area mixed sum = %g, expected 1', sum(va)));

%% laplace_beltrami: row sums are zero (constant in the kernel)
fprintf('Testing laplace_beltrami...\n');
A = laplace_beltrami(face, vertex);
rowsums = full(sum(A, 2));
assert(all(abs(rowsums) < 1e-10), ...
    sprintf('laplace_beltrami max row-sum = %g, expected 0', max(abs(rowsums))));

%% compute_adjacency_matrix: symmetric and 4 neighbors for the diagonal pair
fprintf('Testing compute_adjacency_matrix...\n');
am = compute_adjacency_matrix(face);
assert(isequal(am, am'), 'adjacency matrix should be symmetric');
assert(nnz(am) == 10, ...
    sprintf('adjacency matrix has %d nonzeros, expected 10', nnz(am)));

%% io roundtrip: write_off then read_off recovers face/vertex
fprintf('Testing write_off + read_off roundtrip...\n');
tmpdir = tempname;
mkdir(tmpdir);
cleanup = onCleanup(@() rmdir(tmpdir, 's'));
tmpfile = fullfile(tmpdir, 'square.off');
write_off(tmpfile, face, vertex);
[face2, vertex2] = read_off(tmpfile);
assert(isequal(face, face2), 'read_off/write_off roundtrip failed for face');
assert(norm(vertex - vertex2, 'fro') < 1e-6, ...
    'read_off/write_off roundtrip failed for vertex');

fprintf('SUCCESS\n');
