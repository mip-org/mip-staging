% Test script for safe (SAFE toolbox) package.
% Uses only pure-MATLAB parts of the toolbox (no MathWorks toolboxes).

rng('default');

%% Elementary Effects Test (Morris method) on the Ishigami-Homma function
fprintf('Testing Morris_sampling + EET_indices...\n');
M = 3;
xmin = -pi * ones(1, M);
xmax =  pi * ones(1, M);
r = 50;   % number of elementary effects
L = 6;    % number of levels in the sampling grid

X = Morris_sampling(r, xmin, xmax, L);   % (r*(M+1), M)
assert(isequal(size(X), [r*(M+1), M]), 'Morris_sampling returned wrong size');
assert(all(X(:) >= -pi - 1e-12) && all(X(:) <= pi + 1e-12), ...
    'Morris samples out of range');

a = 2; b = 1;   % Ishigami-Homma: y = sin(x1) + a sin(x2)^2 + b x3^4 sin(x1)
Y = sin(X(:,1)) + a*sin(X(:,2)).^2 + b*X(:,3).^4.*sin(X(:,1));

[mi, sigma] = EET_indices(r, xmin, xmax, X, Y, 'trajectory');
assert(numel(mi) == M && numel(sigma) == M, 'EET_indices wrong output size');
assert(all(isfinite(mi)) && all(isfinite(sigma)), 'EET indices not finite');
assert(all(sigma >= 0), 'negative EE standard deviation');

% Note: AAT_sampling/OAT_sampling need the Statistics and Machine Learning
% Toolbox (inverse CDFs like unifinv; 'lhs' additionally uses pdist), so they
% are not exercised here — the CI runner has no toolboxes.

%% Utility functions
fprintf('Testing empiricalcdf...\n');
F = empiricalcdf(Y, Y);
assert(numel(F) == numel(Y), 'empiricalcdf wrong output size');
assert(all(F >= 0 & F <= 1), 'empiricalcdf values outside [0,1]');

fprintf('SUCCESS\n');
