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

% Fix up Linux .mexa64 DT_NEEDED entries so they load on end-user machines:
%
%   1. MATLAB's libmex.so / libmx.so / libMatlabEngine.so have no DT_SONAME,
%      so `ld` embeds the full absolute path it was given into DT_NEEDED.
%      That bakes the CI runner's MATLAB install path into every .mexa64
%      and breaks loading on any other machine. Rewrite each absolute
%      NEEDED entry to its basename so the loader resolves it via MATLAB's
%      own LD_LIBRARY_PATH at dlopen time.
%
%   2. libMatlabEngine.so (modern C++ MEX API) lives under
%      <matlabroot>/extern/bin/glnxa64/, which is NOT on MATLAB's runtime
%      LD_LIBRARY_PATH — so even the basename won't resolve. Fortunately
%      gptoolbox's MEX files don't use any Engine symbols (verified via
%      `nm --undefined-only`); the linker pulled it in just because CMake
%      listed it in Matlab_LIBRARIES. Drop the NEEDED entry entirely.
%
% patchelf must be available on PATH; the GitHub Actions workflow installs
% it via apt. See adding_a_package.md for the general pattern.
if isunix && ~ismac
    [status, ~] = system('command -v patchelf >/dev/null 2>&1');
    if status ~= 0
        error(['patchelf not found on PATH. Install it in the workflow ' ...
               '(`sudo apt install -y patchelf`) before running the MEX bundle step.']);
    end

    fprintf('Rewriting absolute NEEDED entries to basenames...\n');
    mexFiles = dir(fullfile(mexDir, '*.mexa64'));
    for ii = 1:numel(mexFiles)
        f = fullfile(mexFiles(ii).folder, mexFiles(ii).name);
        [~, dump] = system(sprintf('readelf -d "%s"', f));
        needed = regexp(dump, 'NEEDED\)\s*Shared library: \[([^\]]+)\]', 'tokens');
        for jj = 1:numel(needed)
            dep = needed{jj}{1};
            if startsWith(dep, '/')
                [~, n, ext] = fileparts(dep);
                base = [n ext];
                [status, out] = system(sprintf( ...
                    'patchelf --replace-needed "%s" "%s" "%s"', dep, base, f));
                if status ~= 0
                    error('patchelf --replace-needed failed on %s: %s', ...
                          mexFiles(ii).name, out);
                end
            end
        end
        [status, out] = system(sprintf( ...
            'patchelf --remove-needed libMatlabEngine.so "%s"', f));
        if status ~= 0
            error('patchelf --remove-needed failed on %s: %s', ...
                  mexFiles(ii).name, out);
        end
    end
end

fprintf('=== gptoolbox MEX compilation complete ===\n');
