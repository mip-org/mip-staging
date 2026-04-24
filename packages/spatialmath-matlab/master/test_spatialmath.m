% Test script for spatialmath-matlab.

rng('default');

%% Basic rotation matrices
fprintf('Testing rotx/roty/rotz...\n');
Rx = rotx(pi/2);
assert(isequal(size(Rx), [3 3]), 'rotx must return 3x3');
assert(norm(Rx * [0; 1; 0] - [0; 0; 1]) < 1e-12, ...
    'rotx(pi/2) * [0;1;0] should be [0;0;1]');

Ry = roty(pi/2);
Rz = rotz(pi/2);
assert(abs(det(Rx) - 1) < 1e-12 && abs(det(Ry) - 1) < 1e-12 && ...
       abs(det(Rz) - 1) < 1e-12, 'rotation matrices must have det == 1');

%% transl / trotx / r2t / t2r
fprintf('Testing homogeneous transforms...\n');
T = transl([1 2 3]);
assert(isequal(size(T), [4 4]), 'transl must return 4x4');
assert(norm(T(1:3, 4) - [1; 2; 3]) < 1e-12, 'translation part must match');
assert(isequal(T(1:3, 1:3), eye(3)), 'rotation part of pure transl must be I');

Tx = trotx(pi/4);
assert(isequal(size(Tx), [4 4]), 'trotx must return 4x4');
assert(norm(Tx(1:3, 1:3) - rotx(pi/4)) < 1e-12, ...
    'trotx rotation block must match rotx');

%% r2t, t2r roundtrip
R0 = rotx(0.3);
T0 = r2t(R0);
assert(isequal(size(T0), [4 4]));
assert(norm(t2r(T0) - R0) < 1e-12, 'r2t/t2r roundtrip failed');

%% SE3 class
fprintf('Testing SE3 class...\n');
se = SE3(1, 2, 3);
assert(isa(se, 'SE3'));
M = se.double;
assert(isequal(size(M), [4 4]));
assert(norm(M(1:3, 4) - [1; 2; 3]) < 1e-12, ...
    'SE3(1,2,3).double translation must be [1;2;3]');

se2 = SE3.Rx(pi/2);
M2 = se2.double;
assert(norm(M2(1:3, 1:3) - rotx(pi/2)) < 1e-12, ...
    'SE3.Rx(pi/2) rotation must match rotx(pi/2)');

%% SO3 class
fprintf('Testing SO3 class...\n');
so = SO3.Rx(pi/3);
assert(isa(so, 'SO3'));
R = so.double;
assert(norm(R - rotx(pi/3)) < 1e-12, 'SO3.Rx must match rotx');

%% Unit quaternion roundtrip
fprintf('Testing UnitQuaternion...\n');
R1 = rotz(0.5) * roty(0.3) * rotx(0.2);
q = UnitQuaternion(R1);
assert(norm(q.R - R1) < 1e-10, 'UnitQuaternion(R).R should recover R');

fprintf('SUCCESS\n');
