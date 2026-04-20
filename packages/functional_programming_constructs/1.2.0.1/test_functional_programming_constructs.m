% Test script for functional_programming_constructs.

rng('default');

fprintf('Checking functions are on the path...\n');
for name = {'iif', 'tern', 'map', 'mapc', 'curly', 'paren', 'last', ...
            'loop', 'forloop', 'dowhile', 'recur', 'use', 'void', 'wrap'}
    assert(~isempty(which(name{1})), ...
        sprintf('%s is not on the MATLAB path', name{1}));
end

fprintf('Testing iif...\n');
assert(isequal(iif(false, @() 1, true, @() 2), 2));
assert(isequal(iif(true,  @() 'a', true, @() 'b'), 'a'));

fprintf('Testing tern...\n');
assert(isequal(tern(true,  @() 10, @() 20), 10));
assert(isequal(tern(false, @() 10, @() 20), 20));

fprintf('Testing curly...\n');
assert(strcmp(curly({'soup', 1, [1 1 3]}, 1), 'soup'));

fprintf('Testing paren...\n');
assert(isequal(paren(magic(3), 2, 2), 5));

fprintf('Testing last...\n');
assert(isequal(last(1, 2, 3), 3));

fprintf('Testing map...\n');
assert(isequal(map({3, 4}, {@(a, b) a + b, @max}), [7 4]));

fprintf('Testing forloop accumulates...\n');
total = forloop(0, 5, @(acc, k) acc + k);
assert(isequal(total, 15), ...
    sprintf('forloop sum 1..5 should be 15, got %g', total));

fprintf('SUCCESS\n');
