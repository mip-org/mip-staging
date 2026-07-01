% Test script for tfocs.
%
% Exercises the compiled proxAdaptiveL1Mex MEX so the build's MEX-coverage
% gate passes (every shipped MEX must be invoked here). The MEX lives in the
% mexFiles/ subdirectory; prox_Sl1 adds it to the path on demand.

fprintf('Testing tfocs proxAdaptiveL1Mex...\n');
addpath(fullfile(tfocs_where, 'mexFiles'));
assert(exist('proxAdaptiveL1Mex', 'file') == 3, ...
    'proxAdaptiveL1Mex MEX not found on path (compile.m did not run?)');

% Direct call: solves the ordered-L1 prox on a descending vector v1 with
% positive weights v2.
v1 = [5; 3; 2];
v2 = [1; 1; 1];
v = proxAdaptiveL1Mex(v1, v2);
assert(isequal(size(v), size(v1)), 'unexpected proxAdaptiveL1Mex output size');
assert(all(isfinite(v)), 'proxAdaptiveL1Mex returned non-finite values');

% End-to-end through prox_Sl1, whose proximity operator dispatches to the MEX.
op = prox_Sl1([3; 2; 1]);
[~, x] = op([4; 1; -5], 1);
assert(numel(x) == 3, 'prox_Sl1 output size mismatch');
assert(all(isfinite(x)), 'prox_Sl1 returned non-finite values');

fprintf('SUCCESS\n');
