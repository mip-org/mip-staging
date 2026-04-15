% Test script for docmaker.
%
% The public entry points (docconvert, docrun) require network access to
% the GitHub or GitLab Markdown API and authenticated tokens, so we cannot
% exercise them end-to-end in a headless build. Instead, confirm that the
% four documented functions are on the path, that the +docmaker namespace
% is reachable, and that bundled resources ship alongside the code.

fprintf('Testing docmaker path entries...\n');
assert(exist('docconvert', 'file') == 2, ...
    'docconvert is not on the MATLAB path');
assert(exist('docrun', 'file') == 2, ...
    'docrun is not on the MATLAB path');
assert(exist('docindex', 'file') == 2, ...
    'docindex is not on the MATLAB path');
assert(exist('docdelete', 'file') == 2, ...
    'docdelete is not on the MATLAB path');

fprintf('Testing +docmaker namespace...\n');
assert(exist('docmaker.converter', 'file') == 2, ...
    'docmaker.converter is not reachable via the +docmaker namespace');

fprintf('Testing bundled resources...\n');
pkgRoot = fileparts(which('docconvert'));
resourcesDir = fullfile(pkgRoot, 'resources');
assert(isfolder(resourcesDir), ...
    sprintf('Expected resources directory at %s', resourcesDir));
xslFile = fullfile(resourcesDir, 'helptoc.xsl');
assert(isfile(xslFile), ...
    sprintf('Expected %s', xslFile));

fprintf('SUCCESS\n');
