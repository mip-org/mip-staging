% Test script for robotics-toolbox-matlab (pure-MATLAB layer).
% Runs without the frne MEX file; forward kinematics falls back to the
% M-file recursive Newton-Euler path.

rng('default');

%% spatialmath dependency is loaded
fprintf('Checking spatialmath dependency...\n');
assert(exist('rotx', 'file') == 2, 'rotx missing: spatialmath not on path');
assert(exist('SE3', 'class') == 8 || exist('SE3', 'file') == 2, ...
    'SE3 class missing: spatialmath not on path');

%% Load the Puma 560 model (canonical RTB test robot)
fprintf('Loading Puma 560 model...\n');
mdl_puma560;   % creates p560 in the caller workspace
assert(exist('p560', 'var') == 1, 'mdl_puma560 did not create p560');
assert(isa(p560, 'SerialLink'), 'p560 should be a SerialLink');
assert(p560.n == 6, sprintf('p560.n = %d, expected 6', p560.n));

%% Forward kinematics at the zero configuration
fprintf('Testing forward kinematics...\n');
T = p560.fkine(zeros(1, 6));
% T may be a SE3 object or a 4x4 double depending on the version
if isa(T, 'SE3')
    T = T.double;
end
assert(isequal(size(T), [4 4]), 'fkine must return 4x4');
assert(norm(T(1:3, 1:3) * T(1:3, 1:3)' - eye(3)) < 1e-10, ...
    'fkine rotation block must be orthogonal');
assert(abs(det(T(1:3, 1:3)) - 1) < 1e-10, ...
    'fkine rotation block must have det == 1');

%% Inverse kinematics roundtrip (ikine6s is analytical for the Puma 560)
fprintf('Testing inverse kinematics roundtrip...\n');
qtrue = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6];
Ttarget = p560.fkine(qtrue);
qsol = p560.ikine6s(Ttarget);
Tback = p560.fkine(qsol);
if isa(Ttarget, 'SE3'), Ttarget = Ttarget.double; end
if isa(Tback, 'SE3'), Tback = Tback.double; end
assert(norm(Ttarget - Tback, 'fro') < 1e-6, ...
    'fkine(ikine6s(T)) should recover T');

%% jtraj: 50-point joint-space trajectory from zero to qtrue
fprintf('Testing jtraj...\n');
Q = jtraj(zeros(1,6), qtrue, 50);
assert(isequal(size(Q), [50 6]), ...
    sprintf('jtraj produced %dx%d, expected 50x6', size(Q,1), size(Q,2)));
assert(norm(Q(1, :)) < 1e-12, 'jtraj first row should be start');
assert(norm(Q(end, :) - qtrue) < 1e-12, 'jtraj last row should be end');

fprintf('SUCCESS\n');
