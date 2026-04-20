% Test script for memorygraph.

%% Functions are on the path
fprintf('Checking memorygraph + vline are on path...\n');
assert(exist('memorygraph', 'file') == 2, 'memorygraph.m not on path');
assert(exist('vline', 'file') == 2, 'vline.m not on path');

%% Record a short trace and read it back
fprintf('Recording a short memorygraph trace...\n');
opts.dt = 0.2;
memorygraph('start', opts);
cleanupObj = onCleanup(@() memorygraph('done'));
pause(1.5);
memorygraph('label', 'midpoint');
pause(1.5);

[bytes, est_times, cpu_times, cpu_usages, labelstrings, labeltimes] = ...
    memorygraph('get');

assert(~isempty(bytes), 'memorygraph recorded no samples');
assert(isequal(numel(bytes), numel(est_times), ...
               numel(cpu_times), numel(cpu_usages)), ...
    'bytes / est_times / cpu_times / cpu_usages length mismatch');
assert(all(bytes > 0), 'expected all byte samples to be positive');
assert(any(strcmp(labelstrings, 'midpoint')), ...
    'label "midpoint" was not recorded');
assert(numel(labelstrings) == numel(labeltimes), ...
    'labelstrings / labeltimes length mismatch');

clear cleanupObj;   % triggers memorygraph('done')

fprintf('SUCCESS\n');
