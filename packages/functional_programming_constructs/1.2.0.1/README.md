# functional_programming_constructs

A small collection of MATLAB helpers that make functional and
anonymous-function code more expressive: inline conditionals (`iif`,
`tern`), accessor wrappers (`curly`, `paren`), statement sequencing
(`last`, `use`, `void`, `wrap`), and looping / recursion helpers
(`loop`, `forloop`, `dowhile`, `recur`, `map`, `mapc`).

- Upstream: https://www.mathworks.com/matlabcentral/fileexchange/39735-functional-programming-constructs
- Author: Tucker McClure (The MathWorks, Inc.)
- Version: 1.2.0.1

## License

The upstream license is a BSD-3-Clause variant whose third clause limits
the end-user grant to use "in conjunction with MathWorks products and
service offerings." Redistribution is permitted; compliance with the
use restriction is the installer's responsibility. See `license.txt`
for the full text.

## What is shipped

All `.m` files ship at the package root and are on the MATLAB path
after `mip load`. The upstream `html/` directory (pre-rendered demo
output) is stripped from the bundle — run
`functional_programming_examples` at the MATLAB prompt to regenerate
it locally.

## Install

```matlab
mip install --channel mip-org/staging functional_programming_constructs
mip load functional_programming_constructs
```

## Usage

```matlab
safe_normalize = @(x) iif(all(x == 0), @() x, ...
                          true,        @() x / sqrt(sum(x.^2)));
y = safe_normalize([3 4]);   % [0.6 0.8]

second = curly({'a', 'b', 'c'}, 2);   % 'b'
row    = paren(magic(3), 2, :);       % [3 5 7]
```
