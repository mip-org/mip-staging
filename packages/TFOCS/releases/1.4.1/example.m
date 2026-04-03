% Example: Solve a LASSO problem with TFOCS
%
% Finds x minimizing  0.5*||A*x - b||^2 + lambda*||x||_1
% This is a standard sparse recovery / compressed sensing problem.

mip load --channel mip-org/staging TFOCS --install

% Problem setup
n = 200;   % signal dimension
m = 80;    % number of measurements
k = 10;    % sparsity level

% Generate a sparse signal
x_true = zeros(n, 1);
support = randperm(n, k);
x_true(support) = randn(k, 1);

% Measurement matrix and noisy observations
A = randn(m, n) / sqrt(m);
noise = 0.01 * randn(m, 1);
b = A * x_true + noise;

% Regularization parameter
lambda = 0.1 * norm(A' * b, 'inf');

% Solve LASSO using TFOCS
x0 = zeros(n, 1);
opts.maxIts = 500;
opts.tol = 1e-8;
opts.printEvery = 100;

x_tfocs = solver_L1RLS(A, b, lambda, x0, opts);

% Results
fprintf('\nTrue sparsity:      %d nonzeros\n', nnz(x_true));
fprintf('Recovered nonzeros: %d (threshold 1e-3)\n', nnz(abs(x_tfocs) > 1e-3));
fprintf('Relative error:     %.2e\n', norm(x_tfocs - x_true) / norm(x_true));
