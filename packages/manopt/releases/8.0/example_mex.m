% Example: Low-rank matrix completion using euclideanlargefactory (requires MEX)
%
% Recovers a low-rank matrix from a subset of observed entries.
% This uses euclideanlargefactory and sparseentries, which depend on
% the compiled MEX functions spmaskmult and setsparseentries.

mip load --channel mip-org/staging manopt --install

% Problem setup: recover a rank-r matrix of size m x n from partial entries
m = 200;
n = 150;
r = 5;

% Ground truth low-rank matrix
L_true = randn(m, r);
R_true = randn(n, r);

% Observe a random subset of entries (about 5*r*(m+n) entries)
num_obs = min(5 * r * (m + n), m * n);
idx = randperm(m * n, num_obs);
[I, J] = ind2sub([m, n], idx);
mask = sparse(I, J, ones(num_obs, 1), m, n);
observed = sparse(I, J, sum(L_true(I, :) .* R_true(J, :), 2), m, n);

% Define the manifold: fixed-rank matrices of size m x n with rank r
manifold = fixedrankembeddedfactory(m, n, r);

% Set up the problem: minimize ||P_mask(L*R' - observed)||^2
%
% euclideanlargefactory is used internally by fixedrankembeddedfactory
% to handle sparse inner products efficiently via MEX.
problem.M = manifold;
problem.cost = @cost;
problem.egrad = @egrad;

    function f = cost(X)
        LR_entries = sparseentries(mask, X.U * X.S, X.V);
        residual = LR_entries - nonzeros(observed);
        f = 0.5 * (residual' * residual);
    end

    function g = egrad(X)
        LR_entries = sparseentries(mask, X.U * X.S, X.V);
        residual = LR_entries - nonzeros(observed);
        E = replacesparseentries(mask, residual);
        g.U = E * (X.V * X.S');
        g.S = X.U' * E * X.V;
        g.V = E' * (X.U * X.S);
    end

% Solve
options.maxiter = 200;
options.verbosity = 1;
[X_opt, f_opt, info] = conjugategradient(problem, [], options);

% Reconstruct and compare
X_recovered = X_opt.U * X_opt.S * X_opt.V';
X_true = L_true * R_true';

rel_error = norm(X_recovered - X_true, 'fro') / norm(X_true, 'fro');
fprintf('\nRelative recovery error: %.2e\n', rel_error);
fprintf('Final cost: %.2e\n', f_opt);
