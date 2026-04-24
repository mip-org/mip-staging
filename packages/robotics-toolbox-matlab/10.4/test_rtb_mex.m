% Test script for robotics-toolbox-matlab with the frne MEX present.
% Exercises everything the pure-MATLAB test covers, plus verifies that
% SerialLink.fast is true (i.e. frne was picked up) and that rne returns
% a finite torque vector of the right size.

test_rtb;   % run the pure-MATLAB assertions first

fprintf('Checking frne MEX is in use...\n');
assert(exist('frne') == 3, ...
    'frne MEX not found on path; compile step failed');

%% SerialLink.fast should be true once frne is on the path. Rebuild the
%% robot inside this script so the constructor picks up the MEX.
mdl_puma560;
assert(p560.fast == true, ...
    'p560.fast should be true with frne available');

fprintf('Testing rne with MEX backend...\n');
q = zeros(1, 6);
qd = zeros(1, 6);
qdd = zeros(1, 6);
tau = p560.rne(q, qd, qdd);
assert(numel(tau) == 6, ...
    sprintf('rne returned %d entries, expected 6', numel(tau)));
assert(all(isfinite(tau)), 'rne returned non-finite torques');

fprintf('SUCCESS\n');
