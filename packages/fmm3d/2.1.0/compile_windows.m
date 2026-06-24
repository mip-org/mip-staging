function compile_windows()

% Build the fmm3d MEX files (Windows). cwd is the package source root.
%
% The MinGW-w64 toolchain is selected by setup_mex_compilers, so here we just
% call mingw32-make/gfortran and unadorned mex() calls. mingw64.xml links
% -static, so each .mexw64 bakes in libgfortran/libquadmath/libgomp and needs
% no runtime-library bundling. See notes/MATLAB-MINGW.md.
%
% We build only the static library (the MEX does not need the .dll), then link
% the two checked-in mwrap gateways directly:
%   fmm3d         - the modern API (lfmm3d/hfmm3d/stfmm3d/emfmm3d, *3ddir)
%   fmm3d_legacy  - the legacy CMCL API (lfmm3dpart/hfmm3dpart, *partdirect)
% FFLAGS is overridden to drop the makefile's default -march=native (channel
% builds target a generic CPU). OpenMP is enabled.

fprintf('Compiling fmm3d MEX files (Windows/MinGW-w64)...\n');

make_inc = {
    'CC=gcc'
    'CXX=g++'
    'FC=gfortran'
    'FFLAGS=-O3 -funroll-loops -std=legacy -w'
    'CFLAGS=-O3 -funroll-loops -std=gnu17 -w'
    'OMPFLAGS=-fopenmp'
    'OMPLIBS=-lgomp'
};
writelines(make_inc, 'make.inc');

% Build the static library (placed in lib-static/ by the makefile rule).
status = system('mingw32-make libfmm3d.a');
if status ~= 0
    error('fmm3d:makeLibFailed', 'mingw32-make libfmm3d.a failed with exit code %d', status);
end

% Directory holding libgfortran.a / libquadmath.a / libgomp.a, for -L.
[s, fdir] = system('gfortran -print-file-name=libgfortran.a');
if s ~= 0
    error('fmm3d:gfortran', 'could not locate gfortran runtime libraries');
end
fdir = fileparts(strtrim(fdir));

staticLib = fullfile('lib-static', 'libfmm3d.a');

% -DMWF77_UNDERSCORE1 selects gfortran's single-trailing-underscore symbol
% mangling for the mwrap gateways; -D_OPENMP matches the OpenMP-enabled lib.
mex('-compatibleArrayDims', '-DMWF77_UNDERSCORE1', '-D_OPENMP', ...
    fullfile('matlab', 'fmm3d.c'), staticLib, ...
    ['-L' fdir], '-lgfortran', '-lquadmath', '-lgomp', ...
    '-outdir', 'matlab', '-output', 'fmm3d');

mex('-compatibleArrayDims', '-DMWF77_UNDERSCORE1', '-D_OPENMP', ...
    fullfile('matlab', 'fmm3d_legacy.c'), staticLib, ...
    ['-L' fdir], '-lgfortran', '-lquadmath', '-lgomp', ...
    '-outdir', 'matlab', '-output', 'fmm3d_legacy');

fprintf('fmm3d MEX compilation completed.\n');

end
