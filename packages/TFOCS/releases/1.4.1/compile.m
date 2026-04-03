% Compile TFOCS MEX files
% compile.m runs with cwd set to the package source root

fprintf('=== Compiling TFOCS MEX files ===\n');

mexDir = fullfile(pwd, 'mexFiles');

% Simple C files
fprintf('Compiling proxAdaptiveL1Mex...\n');
mex('-largeArrayDims', ...
    fullfile(mexDir, 'proxAdaptiveL1Mex.c'), ...
    '-outdir', mexDir);

fprintf('Compiling shrink_mex...\n');
mex('-largeArrayDims', ...
    fullfile(mexDir, 'shrink_mex.c'), ...
    '-outdir', mexDir);

% C++ files with OpenMP (fall back without if unavailable)
cxxFiles = {'shrink_mex2.cc', 'prox_l1_and_sum_worker_mex.cc'};
for i = 1:numel(cxxFiles)
    srcFile = fullfile(mexDir, cxxFiles{i});
    fprintf('Compiling %s...\n', cxxFiles{i});
    try
        mex(srcFile, ...
            'CXXFLAGS="$CXXFLAGS -O2 -fopenmp"', ...
            'CXXLIBS="$CXXLIBS -lgomp"', ...
            '-outdir', mexDir);
    catch
        fprintf('  OpenMP not available, compiling without...\n');
        try
            mex(srcFile, ...
                'CXXFLAGS="$CXXFLAGS -O2"', ...
                '-outdir', mexDir);
        catch e
            fprintf('  Warning: failed to compile %s: %s\n', cxxFiles{i}, e.message);
        end
    end
end

fprintf('=== TFOCS MEX compilation complete ===\n');
