% Compile gptoolbox MEX files via the upstream CMake build.
% compile.m runs with cwd set to the package source root.
%
% We disable the heavy libigl features (CGAL, Embree, El Topo, XML) so the
% build fits within GitHub runner time/disk budgets. The remaining libigl
% features (core, predicates, tetgen, triangle, cycodebase) cover ~31 of
% the ~49 MEX files shipped by upstream.
%
% Static linking:
%   - Linux:   -static-libstdc++ -static-libgcc on shared/module linker flags
%   - macOS:   libc++ is OS-provided; vcpkg defaults to static for third-party
%   - Windows: vcpkg x64-windows-static-md triplet gives static deps with the
%              dynamic MSVC runtime that MATLAB MEX requires

fprintf('=== Compiling gptoolbox MEX files ===\n');

srcRoot = pwd;
mexDir = fullfile(srcRoot, 'mex');
buildDir = fullfile(mexDir, 'build');

if ~exist(mexDir, 'dir')
    error('mex/ directory not found at %s', mexDir);
end

if ~exist(buildDir, 'dir')
    mkdir(buildDir);
end

cmakeArgs = { ...
    sprintf('cmake "%s" -B "%s"', mexDir, buildDir), ...
    ' -DCMAKE_BUILD_TYPE=Release', ...
    sprintf(' -DMatlab_ROOT_DIR="%s"', matlabroot), ...
    ' -DLIBIGL_COPYLEFT_CGAL=OFF', ...
    ' -DLIBIGL_EMBREE=OFF', ...
    ' -DWITH_ELTOPO=OFF', ...
    ' -DLIBIGL_XML=OFF'};

if isunix && ~ismac
    cmakeArgs{end+1} = ' -DCMAKE_SHARED_LINKER_FLAGS="-static-libstdc++ -static-libgcc"';
    cmakeArgs{end+1} = ' -DCMAKE_MODULE_LINKER_FLAGS="-static-libstdc++ -static-libgcc"';
end

if ismac && strcmp(computer('arch'), 'maca64')
    cmakeArgs{end+1} = ' -DCMAKE_OSX_ARCHITECTURES=arm64';
    cmakeArgs{end+1} = ' -DMatlab_MEX_EXTENSION=mexmaca64';
end

if ispc
    cmakeArgs{end+1} = ' -DVCPKG_TARGET_TRIPLET=x64-windows-static-md';
    cmakeArgs{end+1} = ' -DMSVC_RUNTIME=dynamic';
    cmakeArgs{end+1} = ' -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL';
    cmakeArgs{end+1} = ' -DCMAKE_POLICY_DEFAULT_CMP0091=NEW';
end

cmakeCmd = strjoin(cmakeArgs, '');
fprintf('Configuring: %s\n', cmakeCmd);
[status, output] = system(cmakeCmd);
fprintf('%s', output);
if status ~= 0
    error('CMake configuration failed (exit code %d)', status);
end

nproc = maxNumCompThreads;
buildCmd = sprintf('cmake --build "%s" --config Release -j%d', buildDir, nproc);
fprintf('Building: %s\n', buildCmd);
[status, output] = system(buildCmd);
fprintf('%s', output);
if status ~= 0
    error('CMake build failed (exit code %d)', status);
end

fprintf('=== gptoolbox MEX compilation complete ===\n');
