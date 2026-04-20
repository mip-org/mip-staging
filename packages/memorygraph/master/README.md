# memorygraph

[memorygraph](https://github.com/ahbarnett/memorygraph) is a small
MATLAB/octave tool that records true process RAM and CPU usage vs time
by spawning `top` in the background and parsing its output. It is useful
for measuring real peak memory use of a MATLAB workflow without having
to watch `htop` by hand.

- **Author**: Alex Barnett (with contributions from Joakim Anden and Jeremy Magland)
- **License**: Apache-2.0
- **Version**: `master` (upstream has no tagged releases)
- **Repository**: https://github.com/ahbarnett/memorygraph

## Install

```matlab
mip install --channel mip-org/staging memorygraph
mip load memorygraph
```

## What is shipped

Two MATLAB functions at the package root, both on the MATLAB path after
`mip load`:

- `memorygraph` — main entry point (`'start'`, `'get'`, `'plot'`,
  `'label'`, `'done'`)
- `vline` — helper that draws the red fiduciary vertical lines used by
  `memorygraph('plot')`

## Platform support

This package is **Linux-only**. It relies on the GNU `top -b -p <pid>`
batch-mode invocation and the standard `top` output format, neither of
which are available on macOS (BSD `top`) or Windows. For that reason,
the bundle is only produced for `linux_x86_64`; users on other
architectures will see the package as unavailable.

Additional runtime requirements (Linux):

- `top` from `procps` must be on `PATH` (it is on essentially every
  Linux distro).
- The `top` display must use the standard column layout — no
  customizations in `/etc/toprc` or `~/.toprc`.

## Tests

`test_memorygraph.m` loads the two functions, runs a short ~3 s
recording with a label, and asserts that samples were captured, that
the returned arrays are length-consistent, and that the label was
recorded at the correct time.
