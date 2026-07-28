mip install --channel mip-org/staging pivlab
mip load pivlab

% PIVlab is GUI-centric; start it with:
%   PIVlab_GUI
%
% The functions can also be scripted. This example runs the FFT-based PIV
% engine on a synthetic image pair with a known uniform shift.
% Note: piv.piv_FFTmulti requires the Image Processing Toolbox.

rng('default');

% Synthetic particle image pair: smoothed noise, second frame shifted by
% a known amount (u = -7 px, v = +3 px).
N = 160;
A = conv2(rand(N), ones(5)/25, 'same');
B = circshift(A, [3, -7]);

% PIV analysis: 2 passes, 64->32 px interrogation windows (as in upstream's
% Example_scripts/PIVlab_process_commandline.m; all other options default).
[x, y, u, v, typevector, correlation_map] = piv.piv_FFTmulti( ...
    image1=A, image2=B, ...
    interrogationarea=64, ...
    passes=2, int2=32);

fprintf('median u = %.2f px (expected -7), median v = %.2f px (expected +3)\n', ...
    median(u(:), 'omitnan'), median(v(:), 'omitnan'));

% Postprocessing: validate and smooth the vector field.
u_filt = misc.smoothn(u);
v_filt = misc.smoothn(v);

quiver(x, y, u_filt, v_filt, 'k');
axis ij equal tight;
title('PIVlab: recovered displacement field');

% For complete command-line workflows (batch processing, ensemble
% correlation, session files), load the example scripts:
%   mip load pivlab --with examples
% and open PIVlab_process_commandline.m.
