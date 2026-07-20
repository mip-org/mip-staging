% Test script for safe (SAFE toolbox) package, main release (rebeccamccabe
% fork). Uses only pure-MATLAB parts of the toolbox (no MathWorks toolboxes).

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

%% PAWN model execution (covers the fork's fix)
% Upstream pawn_model_execution calls model_evaluation, a function that does
% not exist anywhere in the toolbox (renamed upstream to model_execution);
% the fork fixes the call. This section fails against unpatched upstream.
fprintf('Testing pawn_model_execution...\n');

% pawn_model_execution requires the model as the *name* of a function file,
% so write a tiny model into a temp directory and put it on the path. It also
% requires at least one extra model argument (with only two inputs its
% NumExtraArg variable is never assigned), so the model takes a parameter.
modelDir = fullfile(tempdir, 'safe_test_pawn_model');
if ~exist(modelDir, 'dir')
    mkdir(modelDir);
end
fid = fopen(fullfile(modelDir, 'safe_test_model.m'), 'w');
assert(fid > 0, 'could not create temporary model function file');
fprintf(fid, 'function y = safe_test_model(x, a)\n');
fprintf(fid, 'y = sin(x(:,1)) + a*sin(x(:,2)).^2 + x(:,3).^4.*sin(x(:,1));\n');
fclose(fid);
addpath(modelDir);

n = 2;    % conditioning subsamples per factor
NC = 10;  % points per subsample
XX = cell(M, n);
for i = 1:M
    for k = 1:n
        XX{i,k} = -pi + 2*pi*rand(NC, M);
    end
end
YY = pawn_model_execution('safe_test_model', XX, a);
assert(isequal(size(YY), [M, n]), 'pawn_model_execution wrong output size');
for i = 1:M
    for k = 1:n
        assert(isequal(size(YY{i,k}), [NC, 1]), ...
            'pawn_model_execution subsample output has wrong size');
        assert(all(isfinite(YY{i,k})), ...
            'pawn_model_execution produced non-finite outputs');
    end
end

rmpath(modelDir);

fprintf('SUCCESS\n');
