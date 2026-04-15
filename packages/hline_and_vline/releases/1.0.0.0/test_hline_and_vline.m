% Test script for hline_and_vline.

fprintf('Checking hline and vline are on the path...\n');
assert(~isempty(which('hline')), 'hline is not on the MATLAB path');
assert(~isempty(which('vline')), 'vline is not on the MATLAB path');

fprintf('Drawing reference lines on an invisible figure...\n');
f = figure('Visible', 'off');
cleanup = onCleanup(@() close(f));
axes(f);
plot(0:10, (0:10).^2);

h1 = hline(42);
assert(all(ishandle(h1)), 'hline returned an invalid handle');

h2 = vline(5);
assert(all(ishandle(h2)), 'vline returned an invalid handle');

fprintf('Drawing a vectorized call with labels...\n');
h3 = hline([10, 50], {'b', 'r'}, {'low', 'high'});
assert(numel(h3) == 2, sprintf('expected 2 handles, got %d', numel(h3)));
assert(all(ishandle(h3)), 'vectorized hline returned invalid handles');

fprintf('SUCCESS\n');
