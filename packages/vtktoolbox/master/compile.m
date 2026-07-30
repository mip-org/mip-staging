% Compile vtkToolbox MEX files (linux_x86_64, macos_arm64, windows_x86_64).
% compile.m runs with cwd set to the package source root.
%
% Two CMake stages, both in scratch dirs outside the package root:
%   1. Build a minimal static VTK from source — only the 19 modules the
%      toolbox links (no rendering, no Python wrapping, no StandAlone IO) —
%      and install it into a throwaway prefix. VTK vendors its own third-party
%      deps, so this stage needs nothing beyond cmake + the compiler.
%   2. Drive the upstream CMakeLists.txt with VTK_DIR pointing at that prefix.
%      matlab_add_mex places the .mex* into MATLAB/, where the package paths
%      pick them up. Eigen (header-only, used by vtkFillSurfaceHoles) is
%      fetched by the upstream CMakeLists via FetchContent (git) when no
%      system Eigen exists.
%
% The MEX are statically linked: VTK is built as static archives with PIC,
% and on Linux libstdc++/libgcc are linked statically. Only OS-provided
% libraries (and MATLAB's own libmx/libmex) remain dynamic.

vtkVersion = '9.5.2';
vtkSeries = '9.5';
vtkUrl = sprintf('https://www.vtk.org/files/release/%s/VTK-%s.tar.gz', ...
    vtkSeries, vtkVersion);

% The VTK components the upstream CMakeLists.txt requests (its VTK_COMPONENTS
% list). Everything else is left to VTK's dependency resolution.
vtkModules = { ...
    'CommonCore', 'CommonDataModel', 'CommonExecutionModel', 'CommonMath', ...
    'CommonMisc', 'CommonSystem', 'FiltersCore', 'FiltersExtraction', ...
    'FiltersFlowPaths', 'FiltersGeneral', 'FiltersGeometry', ...
    'FiltersModeling', 'FiltersParallel', 'FiltersVerdict', 'IOCore', ...
    'IOGeometry', 'IOLegacy', 'IOPLY', 'IOXML'};

% Every MEX the upstream CMakeLists.txt builds (vtkMmg3d is commented out
% upstream; vtkLineOfBlock and vtkPlaneCutter are never wired in). Used to
% verify the build below; must stay in sync with test_vtktoolbox.m.
expectedMex = { ...
    'vtkAlignNodesWithElectrodes', 'vtkAppendFilter', 'vtkAppendPolyData', ...
    'vtkArrayMapperNearestNeighbor', 'vtkBarycentricCoords', ...
    'vtkBooleanOperationPolyDataFilter', 'vtkCellCentroids', ...
    'vtkCellDataToPointData', 'vtkCleanPolyData', 'vtkCleanUnstructuredGrid', ...
    'vtkConnectivityFilter', 'vtkContourFilter', 'vtkDataSetSurfaceFilter', ...
    'vtkExtractEdges', 'vtkFeatureEdges', 'vtkFillSurfaceHoles', ...
    'vtkIntegrateAttributes', 'vtkLinearExtrusionFilter', ...
    'vtkLinearSubdivisionFilter', 'vtkLoopSubdivisionFilter', ...
    'vtkMeshQuality', 'vtkPointDataToCellData', 'vtkRead', ...
    'vtkSmoothPolyDataFilter', 'vtkStreamTracer', 'vtkThreshold', ...
    'vtkTriangleFilter', 'vtkWindowedSincPolyDataFilter', 'vtkWrite'};

fprintf('=== Compiling vtkToolbox MEX files (VTK %s) ===\n', vtkVersion);

% MATLAB injects its own libcurl/libssl onto LD_LIBRARY_PATH, which breaks the
% system curl/git that the download and FetchContent steps shell out to.
% Clear it for the duration of this script; onCleanup restores it.
if isunix && ~ismac
    origLdPath = getenv('LD_LIBRARY_PATH');
    setenv('LD_LIBRARY_PATH', '');
    restoreLdPath = onCleanup(@() setenv('LD_LIBRARY_PATH', origLdPath)); %#ok<NASGU>
end

srcRoot = pwd;
matlabDir = fullfile(srcRoot, 'MATLAB');
if ~exist(fullfile(srcRoot, 'CMakeLists.txt'), 'file')
    error('CMakeLists.txt not found at %s', srcRoot);
end
if ~exist(matlabDir, 'dir')
    error('MATLAB/ directory not found at %s', srcRoot);
end

% feature('numcores'), not maxNumCompThreads: the latter is MATLAB's
% computational-thread cap, which the matlab-actions CI session pins to 1.
nproc = feature('numcores');

% ---- 1. Download and unpack the VTK source ------------------------------
work = tempname;
mkdir(work);
cleanupWork = onCleanup(@() rmdir_silent(work)); %#ok<NASGU>

tarball = fullfile(work, 'vtk.tar.gz');
run_or_error(sprintf('curl -fL --retry 5 -o "%s" "%s"', tarball, vtkUrl), ...
    'download VTK');
% On Windows, call System32 bsdtar by absolute path: some runners put MSYS2's
% GNU tar first on PATH. .tar.gz is safe (gzip decodes in-process); never use
% .tar.xz here (that bsdtar shells out to an external xz that deadlocks).
if ispc
    tarExe = fullfile(getenv('SystemRoot'), 'System32', 'tar.exe');
    run_or_error(sprintf('"%s" -xf "%s" -C "%s"', tarExe, tarball, work), ...
        'extract VTK');
else
    run_or_error(sprintf('tar xf "%s" -C "%s"', tarball, work), 'extract VTK');
end
vtkSrc = fullfile(work, sprintf('VTK-%s', vtkVersion));
if ~isfolder(vtkSrc)
    error('Expected %s after extracting %s', vtkSrc, vtkUrl);
end
delete(tarball);

patch_token_manager_lock(vtkSrc);

% ---- 2. Build and install a minimal static VTK --------------------------
vtkBuild = fullfile(work, 'vtk-build');
vtkPrefix = fullfile(work, 'vtk-install');

% genArg and osArgs apply to BOTH cmake stages (VTK and the toolbox).
genArg = '';
osArgs = '';
if ispc
    genArg = ' -G "Visual Studio 17 2022" -A x64';
    % /MD (MultiThreadedDLL) is CMake's default and matches MATLAB's ABI; set
    % it explicitly so neither stage can drift to /MT.
    osArgs = [' -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL' ...
        ' -DCMAKE_POLICY_DEFAULT_CMP0091=NEW'];
elseif ismac
    % Match the mexopts' minimum-load version (oldest Apple-Silicon macOS) so
    % the static VTK archives don't out-version the MEX.
    osArgs = ' -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0 -DCMAKE_OSX_ARCHITECTURES=arm64';
end

moduleArgs = '';
for m = 1:numel(vtkModules)
    moduleArgs = sprintf('%s -DVTK_MODULE_ENABLE_VTK_%s=YES', ...
        moduleArgs, vtkModules{m});
end

cfgCmd = sprintf(['cmake -S "%s" -B "%s"%s%s' ...
    ' -DCMAKE_BUILD_TYPE=Release' ...
    ' -DCMAKE_INSTALL_PREFIX="%s"' ...
    ' -DCMAKE_INSTALL_LIBDIR=lib' ...
    ' -DBUILD_SHARED_LIBS=OFF' ...
    ' -DCMAKE_POSITION_INDEPENDENT_CODE=ON' ...
    ' -DVTK_GROUP_ENABLE_StandAlone=DONT_WANT' ...
    ' -DVTK_GROUP_ENABLE_Rendering=DONT_WANT' ...
    ' -DVTK_GROUP_ENABLE_Imaging=DONT_WANT' ...
    ' -DVTK_GROUP_ENABLE_MPI=DONT_WANT' ...
    ' -DVTK_GROUP_ENABLE_Qt=DONT_WANT' ...
    ' -DVTK_GROUP_ENABLE_Views=DONT_WANT' ...
    ' -DVTK_GROUP_ENABLE_Web=DONT_WANT' ...
    ' -DVTK_ENABLE_WRAPPING=OFF' ...
    ' -DVTK_ENABLE_REMOTE_MODULES=OFF' ...
    ' -DVTK_BUILD_TESTING=OFF' ...
    ' -DVTK_BUILD_EXAMPLES=OFF' ...
    ' -DVTK_BUILD_DOCUMENTATION=OFF' ...
    '%s'], ...
    to_cmake_path(vtkSrc), to_cmake_path(vtkBuild), genArg, osArgs, ...
    to_cmake_path(vtkPrefix), moduleArgs);
run_or_error(cfgCmd, 'configure VTK');
run_or_error(sprintf('cmake --build "%s" --config Release -j%d', ...
    to_cmake_path(vtkBuild), nproc), 'build VTK');
run_or_error(sprintf('cmake --install "%s" --config Release', ...
    to_cmake_path(vtkBuild)), 'install VTK');

% Free runner disk before the toolbox build: only the install prefix is
% needed from here on.
rmdir_silent(vtkBuild);
rmdir_silent(vtkSrc);

vtkDirGlob = dir(fullfile(vtkPrefix, 'lib', 'cmake', 'vtk-*'));
if numel(vtkDirGlob) ~= 1
    error('Expected exactly one vtk-* cmake dir under %s', ...
        fullfile(vtkPrefix, 'lib', 'cmake'));
end
vtkDir = fullfile(vtkDirGlob.folder, vtkDirGlob.name);

% ---- 3. Build the toolbox MEX with the upstream CMakeLists --------------
tbBuild = fullfile(work, 'toolbox-build');

linkArgs = '';
if isunix && ~ismac
    % matlab_add_mex links via the CMake toolchain (not the mex frontend), so
    % the channel mexopts' static-libstdc++ posture must be re-stated here.
    linkArgs = ' -DCMAKE_SHARED_LINKER_FLAGS="-static-libstdc++ -static-libgcc"';
elseif ispc
    % With the multi-config VS generator, SHARED-library DLLs (which is what
    % matlab_add_mex creates .mexw64 as) honor the RUNTIME output dir, and the
    % un-suffixed CMAKE_LIBRARY_OUTPUT_DIRECTORY the upstream CMakeLists sets
    % would gain a Release/ subdir anyway. Send them straight to MATLAB/.
    linkArgs = sprintf(' -DCMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE="%s"', ...
        to_cmake_path(matlabDir));
end

cfgCmd = sprintf(['cmake -S "%s" -B "%s"%s%s%s' ...
    ' -DCMAKE_BUILD_TYPE=Release' ...
    ' -DVTK_DIR="%s"' ...
    ' -DMatlab_ROOT_DIR="%s"'], ...
    to_cmake_path(srcRoot), to_cmake_path(tbBuild), genArg, osArgs, ...
    linkArgs, to_cmake_path(vtkDir), to_cmake_path(matlabroot));
run_or_error(cfgCmd, 'configure vtkToolbox');
run_or_error(sprintf('cmake --build "%s" --config Release -j%d', ...
    to_cmake_path(tbBuild), nproc), 'build vtkToolbox');

% ---- 4. Verify every expected MEX was produced ---------------------------
missing = {};
for k = 1:numel(expectedMex)
    if ~exist(fullfile(matlabDir, [expectedMex{k} '.' mexext]), 'file')
        missing{end+1} = expectedMex{k}; %#ok<SAGROW>
    end
end
if ~isempty(missing)
    error('vtktoolbox:compile', 'MEX missing after build: %s', ...
        strjoin(missing, ', '));
end

% ---- 5. Linux: normalize DT_NEEDED entries -------------------------------
% CMake-linked MEX bake absolute paths to the build runner's libmex.so /
% libmx.so into DT_NEEDED (MATLAB ships them without a DT_SONAME). Rewrite
% each absolute entry to its basename so they resolve inside any MATLAB
% process, and drop libMatlabEngine.so entirely (classic mx*/mex*-API code
% never calls it). patchelf is installed by the build workflow.
if isunix && ~ismac
    for k = 1:numel(expectedMex)
        mexFile = fullfile(matlabDir, [expectedMex{k} '.' mexext]);
        [st, needed] = system(sprintf('patchelf --print-needed "%s"', mexFile));
        if st ~= 0
            error('patchelf --print-needed failed for %s', mexFile);
        end
        for ln = splitlines(string(needed))'
            entry = strtrim(char(ln));
            if isempty(entry) || ~contains(entry, '/')
                continue;
            end
            [~, base, ext] = fileparts(entry);
            baseName = [base ext];
            if strcmp(baseName, 'libMatlabEngine.so')
                run_or_error(sprintf('patchelf --remove-needed "%s" "%s"', ...
                    entry, mexFile), sprintf('drop %s from %s', baseName, expectedMex{k}));
            else
                run_or_error(sprintf('patchelf --replace-needed "%s" "%s" "%s"', ...
                    entry, baseName, mexFile), ...
                    sprintf('normalize %s in %s', baseName, expectedMex{k}));
            end
        end
    end
end

fprintf('Built %d MEX files.\n', numel(expectedMex));
fprintf('=== vtkToolbox MEX compilation complete ===\n');


function patch_token_manager_lock(vtkSrc)
%PATCH_TOKEN_MANAGER_LOCK  Fix the static-init-order crash in vtktoken.
%
% This is THE bug that kept vtkIntegrateAttributes.mexw64 from loading on
% MATLAB R2023a. ThirdParty/token/vtktoken/token/Token.cxx has:
%
%   static std::mutex s_managerLock;
%   std::shared_ptr<Manager> Token::m_manager;
%
%   Manager* Token::getManagerInternal() {
%     if (!Token::m_manager) {                            // unlocked pre-check
%       std::lock_guard<std::mutex> lock(s_managerLock);  // <-- locks here
%       ...  Token::m_manager = std::make_shared<Manager>();
%
% VTK constructs string tokens from static data at load time (the
% vtkDG*::Sides / SidesOfSides arrays have dynamic initializers), so
% getManagerInternal() runs during static initialization -- and on some link
% orders it locks s_managerLock BEFORE that mutex's own initializer has run.
% The mutex is then still zeroed .bss, which is undefined behavior.
%
% MSVC 14.40+ tolerates a zero-initialized mutex (the tolerance that makes
% constexpr mutex constructors legal), so this is invisible there. 14.29 reads
% a null pointer out of it and faults -- and MATLAB loads MSVCP140.dll from its
% own bin\win64 first, with R2023a (the channel's Windows floor) bundling
% 14.29. Hence: fails on R2023a, loads fine on R2026a (14.44), with an access
% violation at MSVCP140!mtx_do_lock under ucrtbase!initterm.
%
% Fix: make the mutex a function-local static, which C++11 initializes on
% first use with no cross-translation-unit ordering dependency. The #define
% keeps the single lock site unchanged. Reported upstream.
file = fullfile(vtkSrc, 'ThirdParty', 'token', 'vtktoken', 'token', 'Token.cxx');
if ~isfile(file)
    error('patch: %s not found', file);
end
old = 'static std::mutex s_managerLock;';
new = [ ...
    '// mip: function-local static -- see patch_token_manager_lock' newline ...
    'static std::mutex& s_managerLockRef()' newline ...
    '{' newline ...
    '  static std::mutex m;' newline ...
    '  return m;' newline ...
    '}' newline ...
    '#define s_managerLock s_managerLockRef()'];
txt = fileread(file);
if ~contains(txt, old)
    error(['patch: Token.cxx no longer declares s_managerLock at file ' ...
        'scope -- VTK may have fixed it; re-verify before dropping this.']);
end
txt = strrep(txt, old, new);
fid = fopen(file, 'w');
if fid < 0
    error('patch: cannot write %s', file);
end
fwrite(fid, txt);
fclose(fid);
fprintf('  [patched Token.cxx: static-init-order fix (s_managerLock)]\n');
end


function rmdir_silent(d)
if exist(d, 'dir')
    try; rmdir(d, 's'); catch; end
end
end


function p = to_cmake_path(p)
p = strrep(p, '\', '/');
end


function run_or_error(cmd, what)
fprintf('  [%s]\n', what);
[st, out] = system(cmd);
fprintf('%s', out);
if st ~= 0
    error('vtktoolbox:compile', '%s failed (exit %d)', what, st);
end
end
