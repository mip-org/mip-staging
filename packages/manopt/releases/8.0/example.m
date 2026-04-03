% Example: Dominant eigenvector via optimization on the sphere
%
% Finds the leading eigenvector of a symmetric matrix by maximizing
% the Rayleigh quotient x'*A*x on the unit sphere. This is a classic
% use case for Manopt and uses only pure MATLAB (no MEX required).

mip load --channel mip-org/staging manopt --install

% Generate a random symmetric matrix
n = 500;
A = randn(n);
A = 0.5 * (A + A');

% Define the manifold: unit sphere in R^n
manifold = spherefactory(n);

% Set up the optimization problem
problem.M = manifold;
problem.cost  = @(x) -x' * (A * x);
problem.egrad = @(x) -2 * A * x;
problem.ehess = @(x, xdot) -2 * A * xdot;

% Solve with trust-regions
[x, xcost, info] = trustregions(problem);

% Compare with eigs
[v, d] = eigs(A, 1, 'largestreal');

fprintf('\nManopt found eigenvalue:  %.10f\n', -xcost);
fprintf('eigs   found eigenvalue:  %.10f\n', d);
fprintf('Eigenvector agreement (|dot|): %.2e\n', abs(x' * v));
