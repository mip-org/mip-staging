% Compile MEX files for Manopt
% compile.m runs with cwd set to the package source root

fprintf('=== Compiling Manopt MEX files ===\n');

srcRoot = pwd;

% tools/ MEX files
toolsDir = fullfile(srcRoot, 'tools');
fprintf('Compiling spmaskmult...\n');
mex('-largeArrayDims', ...
    fullfile(toolsDir, 'spmaskmult.c'), ...
    '-outdir', toolsDir);

fprintf('Compiling setsparseentries...\n');
mex('-largeArrayDims', ...
    fullfile(toolsDir, 'setsparseentries.c'), ...
    '-outdir', toolsDir);

% ttfixedrank MEX files
ttDir = fullfile(srcRoot, 'manifolds', 'ttfixedrank');

fprintf('Compiling weingarten_omega...\n');
mex('-lmwlapack', '-lmwblas', '-largeArrayDims', ...
    fullfile(ttDir, 'weingarten_omega.c'), ...
    '-outdir', ttDir);

% TTeMPS MEX files
ttempsDir = fullfile(ttDir, 'TTeMPS_1.1');

fprintf('Compiling TTeMPS subsref_mex...\n');
mex('-lmwlapack', '-lmwblas', '-largeArrayDims', ...
    fullfile(ttempsDir, '@TTeMPS', 'subsref_mex.c'), ...
    '-outdir', fullfile(ttempsDir, '@TTeMPS'));

fprintf('Compiling TTeMPS_tangent_omega...\n');
mex('-lmwlapack', '-lmwblas', '-largeArrayDims', ...
    fullfile(ttempsDir, '@TTeMPS_tangent', 'TTeMPS_tangent_omega.c'), ...
    '-outdir', fullfile(ttempsDir, '@TTeMPS_tangent'));

fprintf('Compiling TTeMPS_tangent_orth_omega...\n');
mex('-lmwlapack', '-lmwblas', '-largeArrayDims', ...
    fullfile(ttempsDir, '@TTeMPS_tangent_orth', 'TTeMPS_tangent_orth_omega.c'), ...
    '-outdir', fullfile(ttempsDir, '@TTeMPS_tangent_orth'));

fprintf('Compiling als_solve_mex...\n');
mex('-lmwlapack', '-lmwblas', '-largeArrayDims', ...
    fullfile(ttempsDir, 'algorithms', 'completion', 'als_solve_mex.c'), ...
    '-outdir', fullfile(ttempsDir, 'algorithms', 'completion'));

fprintf('=== Manopt MEX compilation complete ===\n');
