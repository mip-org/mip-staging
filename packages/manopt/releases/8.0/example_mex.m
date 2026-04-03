% Example: Low-rank matrix completion (requires MEX)
%
% Recovers a low-rank matrix from a subset of observed entries.
% Uses sparseentries and replacesparseentries (MEX) via
% euclideanlargefactory, following manopt's own approach.

mip load --channel mip-org/staging manopt --install

% Problem setup
m = 500;
n = 500;
r = 5;

Rmn = euclideanlargefactory(m, n);

% Sample entries: osf * r*(m+n-r) observations
osf = 5;
num_obs = round(osf * r * (m + n - r));
idx = unique(randi(m * n, num_obs + 1000, 1));
idx = idx(1:min(num_obs, numel(idx)));
[I, J] = ind2sub([m, n], idx);
M = sparse(I, J, ones(numel(idx), 1), m, n);

% Ground truth rank-r matrix
Astar.L = randn(m, r);
Astar.R = randn(n, r);
atrue = Rmn.sparseentries(M, Astar);  % sample entries via MEX

% Define problem over fixed-rank matrices
problem.M = fixedrankembeddedfactory(m, n, r);
problem.cost = @(X, store) cost_fn(X, store, Rmn, M, atrue);
problem.egrad = @(X, store) egrad_fn(X, store, Rmn, M, atrue);

options.maxtime = 10;
options.tolgradnorm = 1e-8;
options.tolcost = 1e-12;
options.verbosity = 1;

[X_opt, xcost, info] = trustregions(problem, [], options);

% Evaluate recovery
X_true = Astar.L * Astar.R';
X_rec = X_opt.U * X_opt.S * X_opt.V';
rel_error = norm(X_rec - X_true, 'fro') / norm(X_true, 'fro');
fprintf('\nRelative recovery error: %.2e\n', rel_error);
fprintf('Final cost: %.2e\n', xcost);


function [f, store] = cost_fn(X, store, Rmn, M, atrue)
    if ~isfield(store, 'residue')
        store.residue = Rmn.sparseentries(M, X) - atrue;
    end
    f = 0.5 * norm(store.residue)^2;
end

function [g, store] = egrad_fn(X, store, Rmn, M, atrue)
    if ~isfield(store, 'residue')
        store.residue = Rmn.sparseentries(M, X) - atrue;
    end
    g = replacesparseentries(M, store.residue);
end
