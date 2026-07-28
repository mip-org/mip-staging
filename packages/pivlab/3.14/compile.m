% Compile PIVlab's MEX files.
%
% 1) +plot/fastLICFunction.c -- fast Line Integral Convolution renderer used
%    by the LIC visualization (plot.LIC). Built into +plot/ so the compiled
%    MEX shadows the fastLICFunction.m autocompile shim.
% 2) The four minFunc helpers (mcholC, lbfgsC, lbfgsAddC, lbfgsProdC) that
%    upstream's OptimizationSolvers/minFunc/mexAll.m builds, used by the
%    wOFV (wavelet-based optical flow) optimizer. Built into the compiled/
%    dir where minFunc expects them.
% 3) The four +opencv C++ MEX (opencv_version, opencv_undistort,
%    opencv_calibrate_basic, opencv_calibrate_tilted) -- camera calibration
%    and Scheimpflug/tilted-model undistortion, statically linked against
%    OpenCV 4.x (core+imgproc+calib3d, plus features2d/flann as module deps).
%
% OpenCV acquisition is per-platform (the gptoolbox pattern; see mip.yaml's
% setup: block): brew's opencv@4 bottle on macOS, a pinned minimal 4.13.0
% source build on Linux (no prebuilt static OpenCV exists for glibc 2.28),
% and vcpkg's static-md opencv4 on Windows (upstream PIVlab's own documented
% build). The MEX use decade-stable calibration APIs, so any 4.x works
% (upstream's GUI only checks startsWith(version, '4.')).

% MATLAB injects its own libraries onto LD_LIBRARY_PATH, which breaks the
% system tools (cmake/curl) the Linux OpenCV build shells out to.
if isunix && ~ismac
    origLdPath = getenv('LD_LIBRARY_PATH');
    setenv('LD_LIBRARY_PATH', '');
    restoreLdPath = onCleanup(@() setenv('LD_LIBRARY_PATH', origLdPath)); %#ok<NASGU>
end

fprintf('Compiling +plot/fastLICFunction.c...\n');
mex('-outdir', '+plot', fullfile('+plot', 'fastLICFunction.c'));

minfunc_dir = fullfile('OptimizationSolvers', 'minFunc', 'minFunc');
out_dir = fullfile(minfunc_dir, 'compiled');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end
% The minFunc sources predate the 64-bit array-dims API: they pass int[]
% where the default API wants mwSize[] (a hard error on modern compilers),
% so build them with the 32-bit-dims API they were written for.
sources = {'mcholC.c', 'lbfgsC.c', 'lbfgsAddC.c', 'lbfgsProdC.c'};
for i = 1:numel(sources)
    fprintf('Compiling minFunc %s...\n', sources{i});
    mex('-compatibleArrayDims', '-outdir', out_dir, ...
        fullfile(minfunc_dir, 'mex', sources{i}));
end

% ---- OpenCV MEX ---------------------------------------------------------
if ismac
    % Keg-only bottle installed by mip.yaml setup. Its static .a archives
    % are built for the CI runner's macOS (macos-14), which is the channel's
    % deployment floor (see devnotes/MACOS-DEPLOYMENT-TARGET.md). Transitive
    % deps are OS-provided (libz, OpenCL/Accelerate frameworks).
    [s, prefix] = system('brew --prefix opencv@4');
    if s ~= 0
        error('brew --prefix opencv@4 failed -- is opencv@4 installed?');
    end
    prefix = strtrim(prefix);
    opencv_inc = fullfile(prefix, 'include', 'opencv4');
    libdir = fullfile(prefix, 'lib');
    mods = {'calib3d', 'features2d', 'flann', 'imgproc', 'core'};
    opencv_libs = cellfun(@(m) fullfile(libdir, ['libopencv_' m '.a']), ...
        mods, 'UniformOutput', false);
    % HAL/support archives the modules reference (kleidicv, tegra_hal,
    % ittnotify, ade). Skip the libopencv.sfm.* contrib archives -- unused,
    % and their members would demand ceres/glog.
    helpers = dir(fullfile(libdir, '*.a'));
    helpers = helpers(~contains({helpers.name}, 'opencv'));
    opencv_libs = [opencv_libs, ...
        arrayfun(@(d) fullfile(d.folder, d.name), helpers', 'UniformOutput', false)];
    % TBB stays dynamic on purpose: MATLAB ships oneTBB (libtbb.12.dylib),
    % so mip.build.bundle_runtime_libs classifies it MATLAB-provided and
    % MATLAB resolves it at load time -- same treatment as libgfortran on
    % Linux (see devnotes/MEX-RUNTIME-LIBS.md). zlib and the frameworks are
    % OS-provided.
    [s, tbbPrefix] = system('brew --prefix tbb');
    if s ~= 0
        error('brew --prefix tbb failed -- opencv@4 should have pulled it in');
    end
    tbbPrefix = strtrim(tbbPrefix);
    % The channel clang++.xml sets no -std; the runner's default is pre-C++11
    % and OpenCV 4.x headers refuse anything older than C++11.
    opencv_flags = {['-L' fullfile(tbbPrefix, 'lib')], '-ltbb', '-lz', ...
        'CXXFLAGS=$CXXFLAGS -std=c++17', ...
        'LDFLAGS=$LDFLAGS -framework OpenCL -framework Accelerate -framework Foundation'};
elseif isunix
    % Pinned minimal static build: core+imgproc+calib3d (BUILD_LIST resolves
    % features2d/flann automatically), merged into one libopencv_world.a,
    % bundled static zlib, PIC (the .a links into the MEX .so), no IPP/
    % OpenCL/LAPACK/codecs/media. 4.13.0 quirk: BUILD_LIST-excluded modules
    % are still marked IS_PART_OF_WORLD, so the world CMakeLists calls their
    % configure hooks without their functions being defined. Exactly two
    % hooks exist: imgcodecs (in the list, so its function is defined; with
    % every codec OFF it adds just built-in BMP/PXM readers) and highgui
    % (forced OFF so its guard is false). CPU baseline is OpenCV's portable
    % default (SSE3) with runtime dispatch -- no -march=native hazard.
    url = 'https://github.com/opencv/opencv/archive/refs/tags/4.13.0.tar.gz';
    sha256 = '1d40ca017ea51c533cf9fd5cbde5b5fe7ae248291ddf2af99d4c17cf8e13017d';
    workdir = tempname; mkdir(workdir);
    tarball = fullfile(workdir, 'opencv-4.13.0.tar.gz');
    fprintf('Downloading %s...\n', url);
    websave(tarball, url);
    [s, out] = system(['sha256sum "' tarball '"']);
    if s ~= 0 || ~startsWith(strtrim(out), sha256)
        error('OpenCV tarball hash mismatch:\n%s\nexpected %s', out, sha256);
    end
    fprintf('Extracting...\n');
    untar(tarball, workdir);
    srcdir = fullfile(workdir, 'opencv-4.13.0');
    builddir = fullfile(workdir, 'build');
    prefix = fullfile(workdir, 'install');
    nproc = feature('numcores');
    cfg = sprintf(['cmake -S "%s" -B "%s" -DCMAKE_BUILD_TYPE=Release ' ...
        '-DCMAKE_INSTALL_PREFIX="%s" -DBUILD_SHARED_LIBS=OFF ' ...
        '-DBUILD_LIST=core,imgproc,calib3d,imgcodecs -DBUILD_opencv_world=ON ' ...
        '-DBUILD_opencv_highgui=OFF ' ...
        '-DBUILD_ZLIB=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON ' ...
        '-DWITH_IPP=OFF -DWITH_ITT=OFF -DWITH_OPENCL=OFF -DWITH_LAPACK=OFF ' ...
        '-DWITH_EIGEN=OFF -DWITH_PNG=OFF -DWITH_JPEG=OFF -DWITH_TIFF=OFF ' ...
        '-DWITH_WEBP=OFF -DWITH_OPENJPEG=OFF -DWITH_JASPER=OFF ' ...
        '-DWITH_OPENEXR=OFF -DWITH_FFMPEG=OFF -DWITH_GSTREAMER=OFF ' ...
        '-DWITH_V4L=OFF -DWITH_GTK=OFF -DWITH_PROTOBUF=OFF ' ...
        '-DBUILD_PROTOBUF=OFF -DBUILD_TESTS=OFF -DBUILD_PERF_TESTS=OFF ' ...
        '-DBUILD_EXAMPLES=OFF -DBUILD_opencv_apps=OFF -DBUILD_JAVA=OFF ' ...
        '-DBUILD_opencv_python3=OFF'], srcdir, builddir, prefix);
    fprintf('Configuring OpenCV:\n  %s\n', cfg);
    [s, out] = system(cfg);
    if s ~= 0; error('OpenCV configure failed:\n%s', out); end
    fprintf('Building OpenCV (-j%d)...\n', nproc);
    [s, out] = system(sprintf('cmake --build "%s" -j %d', builddir, nproc));
    if s ~= 0; error('OpenCV build failed:\n%s', out(max(1, end-4000):end)); end
    [s, out] = system(sprintf('cmake --install "%s"', builddir));
    if s ~= 0; error('OpenCV install failed:\n%s', out); end
    opencv_inc = fullfile(prefix, 'include', 'opencv4');
    world = dir(fullfile(prefix, 'lib*', 'libopencv_world.a'));
    third = dir(fullfile(prefix, 'lib*', 'opencv4', '3rdparty', '*.a'));
    if isempty(world)
        error('libopencv_world.a not found under %s', prefix);
    end
    opencv_libs = arrayfun(@(d) fullfile(d.folder, d.name), ...
        [world; third]', 'UniformOutput', false);
    % Bare mex args, not LDFLAGS: mex puts LDFLAGS before the archives on
    % the link line, and GNU ld resolves left to right, so -ldl there leaves
    % libopencv_world's dlopen/dlsym references undefined.
    opencv_flags = {'-lpthread', '-ldl', '-lrt'};
else
    % vcpkg static-md install from mip.yaml setup. Mirrors upstream's
    % +opencv/build_opencv_mex.m: static archives carry no transitive dep
    % info, so link every .lib in the triplet's lib dir (opencv modules +
    % third-party deps). The MEX itself uses the dynamic MSVC runtime (/MD),
    % matching MATLAB's ABI.
    vcpkg = getenv('VCPKG_INSTALLATION_ROOT');
    if isempty(vcpkg); vcpkg = 'C:\vcpkg'; end
    inst = fullfile(vcpkg, 'installed', 'x64-windows-static-md');
    opencv_inc = fullfile(inst, 'include', 'opencv4');
    libfiles = dir(fullfile(inst, 'lib', '*.lib'));
    if isempty(libfiles)
        error('no .lib files under %s -- did the vcpkg setup step run?', ...
            fullfile(inst, 'lib'));
    end
    opencv_libs = arrayfun(@(d) fullfile(d.folder, d.name), libfiles', ...
        'UniformOutput', false);
    % Same define the overlay triplet applies to the OpenCV build (see
    % vcpkg-triplets/): keep any header-inlined static mutex in the MEX's own
    % objects loadable against MATLAB's pre-14.40 msvcp140.dll.
    opencv_flags = {'COMPFLAGS=$COMPFLAGS /D_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR'};
end

if ~exist(fullfile(opencv_inc, 'opencv2', 'core.hpp'), 'file')
    error('OpenCV headers not found at %s', opencv_inc);
end
cvsources = {'opencv_version.cpp', 'opencv_undistort.cpp', ...
    'opencv_calibrate_basic.cpp', 'opencv_calibrate_tilted.cpp'};
for i = 1:numel(cvsources)
    fprintf('Compiling +opencv/%s...\n', cvsources{i});
    mex('-outdir', '+opencv', ['-I' opencv_inc], ...
        fullfile('+opencv', cvsources{i}), opencv_libs{:}, opencv_flags{:});
end

fprintf('PIVlab MEX compilation done.\n');
