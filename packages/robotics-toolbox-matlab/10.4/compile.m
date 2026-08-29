% Compile RTB's frne MEX file (fast recursive Newton-Euler).
% compile.m runs with cwd set to the package source root.

fprintf('=== Compiling Robotics Toolbox frne MEX ===\n');

srcRoot = pwd;
mexDir = fullfile(srcRoot, 'mex');

flags = {'-largeArrayDims'};
if isunix && ~ismac
    flags{end+1} = 'LDFLAGS=$LDFLAGS -static-libstdc++ -static-libgcc';
end
flags{end+1} = 'CFLAGS=$CFLAGS -std=c99';

mex(flags{:}, ...
    fullfile(mexDir, 'frne.c'), ...
    fullfile(mexDir, 'ne.c'), ...
    fullfile(mexDir, 'vmath.c'), ...
    '-outdir', mexDir);

fprintf('=== frne MEX compilation complete ===\n');
