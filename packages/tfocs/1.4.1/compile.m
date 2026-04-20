% Compile TFOCS MEX files
% compile.m runs with cwd set to the package source root

fprintf('=== Compiling TFOCS MEX files ===\n');

mexDir = fullfile(pwd, 'mexFiles');

% proxAdaptiveL1Mex.c is the only MEX source in v1.4.1
fprintf('Compiling proxAdaptiveL1Mex...\n');
mex('-largeArrayDims', ...
    fullfile(mexDir, 'proxAdaptiveL1Mex.c'), ...
    '-outdir', mexDir);

fprintf('=== TFOCS MEX compilation complete ===\n');
