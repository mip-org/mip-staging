% Test script for arrow.

fprintf('Checking arrow is on the path...\n');
assert(~isempty(which('arrow')), 'arrow is not on the MATLAB path');

fprintf('Drawing a 2D arrow on an invisible figure...\n');
f = figure('Visible', 'off');
cleanup = onCleanup(@() close(f));
axes(f);

h = arrow([0 0], [1 1]);
assert(~isempty(h), 'arrow returned an empty handle');
assert(all(ishandle(h)), 'arrow returned an invalid handle');

fprintf('Drawing a 3D arrow with an explicit length...\n');
h3 = arrow([0 0 0], [1 2 3], 'Length', 10);
assert(~isempty(h3), 'arrow (3D) returned an empty handle');
assert(all(ishandle(h3)), 'arrow (3D) returned an invalid handle');

fprintf('SUCCESS\n');
