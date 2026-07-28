% Channel post-install test for pivlab -- MEX builds.
%
% Exercises the pure-MATLAB layer plus every shipped MEX (the coverage gate
% requires each one to be invoked): +plot/fastLICFunction and the four
% minFunc helpers mcholC, lbfgsC, lbfgsAddC, lbfgsProdC. The CI runners have
% base MATLAB without the Image Processing Toolbox, so the PIV engine itself
% (piv.piv_FFTmulti) is not run here.
rng('default');

fprintf('Checking package layout...\n');
assert(~isempty(which('PIVlab_GUI')), 'PIVlab_GUI.m not found on path');
assert(~isempty(which('PIVlab_settings_default.mat')), ...
    'PIVlab_settings_default.mat not found on path');
assert(~isempty(which('piv.piv_FFTmulti')), 'piv.piv_FFTmulti not found');
assert(~isempty(which('piv.piv_FFTensemble')), 'piv.piv_FFTensemble not found');
assert(~isempty(which('preproc.PIVlab_preproc')), 'preproc.PIVlab_preproc not found');
assert(~isempty(which('minFunc')), 'minFunc (wOFV optimizer) not found on path');

fprintf('Testing misc.inpaint_nans...\n');
[X, Y] = meshgrid(linspace(0, 1, 32));
Z = sin(2*pi*X) .* cos(2*pi*Y);
Zh = Z;
Zh(5, 7) = NaN; Zh(17, 23) = NaN; Zh(24, 12) = NaN;
Zf = misc.inpaint_nans(Zh);
assert(~any(isnan(Zf(:))), 'inpaint_nans left NaNs behind');
assert(max(abs(Zf(:) - Z(:))) < 0.1, ...
    sprintf('inpaint_nans error too large: %g', max(abs(Zf(:) - Z(:)))));

fprintf('Testing misc.smoothn...\n');
noisy = Z + 0.2 * randn(size(Z));
Zs = misc.smoothn(noisy);
assert(all(isfinite(Zs(:))), 'smoothn returned non-finite values');
err_noisy = norm(noisy - Z, 'fro');
err_smooth = norm(Zs - Z, 'fro');
assert(err_smooth < 0.5 * err_noisy, ...
    sprintf('smoothn did not denoise (noisy %g, smoothed %g)', err_noisy, err_smooth));

fprintf('Testing plot.fastLICFunction (LIC MEX)...\n');
% Mirrors how +plot/LIC.m calls it: a vector field, a white-noise image, and
% a box kernel whose column count sets the LIC streamline length.
n = 64;
[Xg, Yg] = meshgrid(linspace(-1, 1, n));
vx = -Yg;   % solid-body rotation
vy = Xg;
noiseImage = rand(n);
kernel = ones(1, 6);
[LICImage, intensity, normvx, normvy] = plot.fastLICFunction( ...
    double(vx), double(vy), noiseImage, kernel);
assert(isequal(size(LICImage), [n n]), 'fastLICFunction: wrong output size');
assert(all(isfinite(LICImage(:))), 'fastLICFunction: non-finite LIC image');
assert(isequal(size(normvx), [n n]) && isequal(size(normvy), [n n]), ...
    'fastLICFunction: wrong normalized-field size');
assert(all(isfinite(intensity(:))), 'fastLICFunction: non-finite intensity');

fprintf('Testing mcholC (modified Cholesky MEX)...\n');
A = randn(12);
H = A * A' + 12 * eye(12);   % symmetric positive definite
[L, D, perm] = mcholC(H);
if isvector(D)
    Dm = diag(D);
else
    Dm = D;
end
recon_err = norm(L * Dm * L' - H(perm, perm), 'fro') / norm(H, 'fro');
assert(recon_err < 1e-10, ...
    sprintf('mcholC factorization mismatch: relative error %g', recon_err));

% Small L-BFGS history with positive curvature (y_i''*s_i > 0), as minFunc
% maintains it.
nv = 10; k = 4;
g = randn(nv, 1);
S = randn(nv, k);
Yv = S * diag(0.5 + rand(k, 1)) + 0.05 * randn(nv, k);
for i = 1:k
    assert(Yv(:, i)' * S(:, i) > 0, 'test setup: curvature not positive');
end
Hdiag = 1.0;

fprintf('Testing lbfgsC against the pure-MATLAB lbfgs...\n');
d_mex = lbfgsC(-g, S, Yv, Hdiag);
d_m = lbfgs(-g, S, Yv, Hdiag);
assert(norm(d_mex - d_m) < 1e-10 * max(1, norm(d_m)), ...
    sprintf('lbfgsC disagrees with lbfgs.m: diff %g', norm(d_mex - d_m)));

fprintf('Testing lbfgsProdC against the pure-MATLAB lbfgsProd...\n');
YS = sum(Yv .* S, 1)';
d_pmex = lbfgsProdC(g, S, Yv, YS, int32(1), int32(k), Hdiag);
d_pm = lbfgsProd(g, S, Yv, YS, 1, k, Hdiag);
assert(norm(d_pmex - d_pm) < 1e-10 * max(1, norm(d_pm)), ...
    sprintf('lbfgsProdC disagrees with lbfgsProd.m: diff %g', norm(d_pmex - d_pm)));

fprintf('Testing lbfgsAddC (in-place correction update)...\n');
S2 = zeros(nv, k);
Y2 = zeros(nv, k);
ynew = randn(nv, 1);
snew = randn(nv, 1);
ys = ynew' * snew;
if ys < 0
    snew = -snew;
    ys = -ys;
end
lbfgsAddC(ynew, snew, Y2, S2, ys, int32(1));
assert(norm(Y2(:, 1) - ynew) < 1e-12 && norm(S2(:, 1) - snew) < 1e-12, ...
    'lbfgsAddC did not write the correction pair into column 1');

fprintf('Testing minFunc end-to-end on the Rosenbrock function...\n');
% PIVlab's minFunc copy reads option fields case-sensitively (uppercase).
opts = struct('DISPLAY', 'none', 'MAXITER', 500, 'MAXFUNEVALS', 2000);
x = minFunc(@rosenbrock, [-1.2; 1], opts);
assert(norm(x - [1; 1]) < 1e-4, ...
    sprintf('minFunc did not converge to [1;1]: got [%g; %g]', x(1), x(2)));

fprintf('Testing opencv.opencv_version...\n');
v = opencv.opencv_version;
assert(ischar(v) && startsWith(v, '4.'), 'unexpected OpenCV version: %s', v);
fprintf('  OpenCV %s\n', v);

fprintf('Testing opencv.opencv_undistort...\n');
% Upstream's own unittest camera: mild barrel distortion, class preserved.
Ku = [80 0 50; 0 80 50; 0 0 1];
Du = [-0.1 0.05 0 0];
img8 = uint8(randi(255, 100, 100));
out8 = opencv.opencv_undistort(img8, Ku, Du);
assert(isa(out8, 'uint8') && isequal(size(out8), size(img8)), ...
    'opencv_undistort must preserve uint8 class and size');
img16 = uint16(65500 + randi(35, 100, 100));
out16 = opencv.opencv_undistort(img16, Ku, Du);
assert(isa(out16, 'uint16'), 'opencv_undistort must preserve uint16 class');
% A narrow high uint16 range must survive without rescaling (interior
% pixels; border pixels may be zero-filled where the map leaves the image).
mid16 = out16(30:70, 30:70);
assert(all(mid16(:) >= 65500), 'opencv_undistort rescaled uint16 values');
% Zero distortion is the identity map.
imgd = rand(100);
outd = opencv.opencv_undistort(imgd, Ku, zeros(1, 4));
assert(isa(outd, 'double') && max(abs(outd(:) - imgd(:))) < 1e-12, ...
    'zero-distortion opencv_undistort should be an exact identity');

% Synthetic calibration target: a planar 9x7 grid (20 mm pitch) projected
% through a known pinhole camera (no distortion) from four tilted poses.
% Both calibrators must recover K and near-zero distortion from exact data.
[gx, gy] = meshgrid(0:8, 0:6);
worldPoints = [gx(:), gy(:)] * 20;
K_true = [900 0 320; 0 900 240; 0 0 1];
rv = {[0.10; 0.05; 0.02], [-0.15; 0.10; -0.05], ...
      [0.05; -0.20; 0.08], [-0.08; -0.12; 0.15]};
tv = {[-80; -60; 500], [-70; -65; 550], [-90; -55; 480], [-75; -70; 520]};
M = size(worldPoints, 1);
imagePoints = zeros(M, 2, numel(rv));
for view_idx = 1:numel(rv)
    R = rotvec_to_matrix(rv{view_idx});
    P = [worldPoints, zeros(M, 1)] * R' + tv{view_idx}';
    imagePoints(:, :, view_idx) = ...
        [K_true(1,1) * P(:,1) ./ P(:,3) + K_true(1,3), ...
         K_true(2,2) * P(:,2) ./ P(:,3) + K_true(2,3)];
end
imageSize = [480, 640];

fprintf('Testing opencv.opencv_calibrate_basic...\n');
[K_est, dist, rvecs, tvecs] = opencv.opencv_calibrate_basic( ...
    imagePoints, worldPoints, imageSize);
assert(abs(K_est(1,1) - 900) < 9 && abs(K_est(2,2) - 900) < 9, ...
    sprintf('calibrate_basic focal off: fx=%g fy=%g', K_est(1,1), K_est(2,2)));
assert(abs(K_est(1,3) - 320) < 5 && abs(K_est(2,3) - 240) < 5, ...
    sprintf('calibrate_basic principal point off: cx=%g cy=%g', ...
    K_est(1,3), K_est(2,3)));
assert(all(abs(dist(:)) < 0.05), 'calibrate_basic distortion should be ~0');
assert(~isempty(rvecs) && ~isempty(tvecs), 'calibrate_basic pose outputs empty');

fprintf('Testing opencv.opencv_calibrate_tilted...\n');
[K_t, dist_t, ~, ~] = opencv.opencv_calibrate_tilted( ...
    imagePoints, worldPoints, imageSize);
assert(numel(dist_t) == 14, ...
    sprintf('calibrate_tilted should return 14 coefficients, got %d', numel(dist_t)));
assert(abs(K_t(1,1) - 900) < 20 && abs(K_t(2,2) - 900) < 20, ...
    sprintf('calibrate_tilted focal off: fx=%g fy=%g', K_t(1,1), K_t(2,2)));
assert(all(abs(dist_t(:)) < 0.1), ...
    'calibrate_tilted distortion (incl. tauX/tauY) should be ~0');

fprintf('SUCCESS\n');

function R = rotvec_to_matrix(r)
% Rodrigues rotation-vector to matrix (as cv::Rodrigues).
theta = norm(r);
if theta < eps
    R = eye(3);
    return
end
k = r / theta;
Kx = [0 -k(3) k(2); k(3) 0 -k(1); -k(2) k(1) 0];
R = eye(3) + sin(theta) * Kx + (1 - cos(theta)) * (Kx * Kx);
end
