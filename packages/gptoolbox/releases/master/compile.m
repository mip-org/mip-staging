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

% MATLAB on Linux injects its own libcurl/libssl into LD_LIBRARY_PATH,
% which breaks the system `curl` that vcpkg bootstrap invokes:
%   curl: symbol lookup error: undefined symbol: curl_global_trace
% Clear LD_LIBRARY_PATH for the duration of this script so subprocesses
% use the system libraries; onCleanup restores it on exit.
if isunix && ~ismac
    origLdPath = getenv('LD_LIBRARY_PATH');
    setenv('LD_LIBRARY_PATH', '');
    restoreLdPath = onCleanup(@() setenv('LD_LIBRARY_PATH', origLdPath));
end

srcRoot = pwd;
mexDir = fullfile(srcRoot, 'mex');
buildDir = fullfile(mexDir, 'build');

if ~exist(mexDir, 'dir')
    error('mex/ directory not found at %s', mexDir);
end

if ~exist(buildDir, 'dir')
    mkdir(buildDir);
end

% Patch mex/CMakeLists.txt to drop the no-CGAL build of triangulate.cpp.
% Upstream triangulate.cpp #includes CGAL headers unconditionally (only
% the switch-case bodies are #ifdef WITH_CGAL guarded), so it cannot
% compile when LIBIGL_COPYLEFT_CGAL=OFF. refine_triangulation.cpp, built
% from the same LIBIGL_RESTRICTED_TRIANGLE block, has no CGAL deps and
% continues to build.
cmakelistsPath = fullfile(mexDir, 'CMakeLists.txt');
fid = fopen(cmakelistsPath, 'r');
content = fread(fid, '*char')';
fclose(fid);

oldBlock = [ ...
    '  else()' newline ...
    '    compile_each("\' newline ...
    'triangulate.cpp;\' newline ...
    '"' newline ...
    '    "${CORE_LIBS};igl::core;igl_restricted::matlab;igl_restricted::triangle")' newline ...
    '  endif()'];
newBlock = '  endif()';
if ~contains(content, oldBlock)
    error(['Could not locate the expected triangulate.cpp else-branch ' ...
           'in mex/CMakeLists.txt. Upstream layout may have changed — ' ...
           'update the patch in compile.m.']);
end
content = strrep(content, oldBlock, newBlock);
fid = fopen(cmakelistsPath, 'w');
fwrite(fid, content);
fclose(fid);
fprintf('Patched mex/CMakeLists.txt to skip triangulate.cpp.\n');

cmakeArgs = { ...
    sprintf('cmake "%s" -B "%s"', mexDir, buildDir), ...
    ' -DCMAKE_BUILD_TYPE=Release', ...
    sprintf(' -DMatlab_ROOT_DIR="%s"', matlabroot), ...
    ' -DLIBIGL_COPYLEFT_CGAL=OFF', ...
    ' -DLIBIGL_EMBREE=OFF', ...
    ' -DWITH_ELTOPO=OFF', ...
    ' -DLIBIGL_XML=OFF', ...
    ' -DCMAKE_SKIP_BUILD_RPATH=TRUE'};

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
