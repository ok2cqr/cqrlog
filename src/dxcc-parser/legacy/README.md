# legacy/

Symlinks to the two units this work replaces:

- `odbec.pas` -> `../../odbec.pas`
- `znacmech.pas` -> `../../znacmech.pas`

They exist so the test runner can compile the legacy engine **from source**
with `-dnuse_ddata`.

Pointing `-Fu` straight at `src/` does not work: a normal CQRLOG build leaves
`src/znacmech.ppu` behind, compiled *without* that define, and FPC happily
reuses the stale unit — which then drags in `dData`, and with it the whole LCL.
A directory that contains only the sources forces a real recompile into
`lib/`, and leaves `src/` untouched.

These are symlinks, not copies, so the tests always run against the real
current source.
