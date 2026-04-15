# hline_and_vline

`hline(y)` and `vline(x)` draw horizontal and vertical reference lines
on the current MATLAB axes. Both accept an optional MATLAB line-spec
string and an optional text label, and both accept vector inputs to
draw several reference lines in one call.

The drawn lines have their `HandleVisibility` set to `'off'`, so they
don't show up in legends or `findobj` — request an output argument if
you need a handle for later manipulation.

- Upstream: https://www.mathworks.com/matlabcentral/fileexchange/1039-hline-and-vline
- Author: Brandon Kuczenski
- Version: 1.0.0.0
- License: BSD-2-Clause

## Install

```matlab
mip install --channel mip-org/staging hline_and_vline
mip load hline_and_vline
```

## Usage

```matlab
plot(t, y);
hline(0, 'k--');                              % zero line
vline(t_event, 'r', 'event');                 % labeled event marker
hline([-1 1], {'b:', 'b:'}, {'low', 'high'}); % multiple in one call
```
