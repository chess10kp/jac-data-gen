# Agent notes

## LLVM slice — reuse the shared copy, never fetch a private one

The `jaseci/` checkout inside this repo is a Jac compiler tree. Its
`jaseci/jac/.llvm-build` is a symlink to the single canonical slice at
`~/repos/jaseci/jac/.llvm-build` (pinned LLVM 22.1.8, see `jaseci/jac/bootstrap/pins.json`).

- Plain `zig build` resolves the slice through the link; `zig build fetch-llvm`
  is a no-op once the marker lib exists. NEVER delete the symlink or fetch a
  private copy — each private `.llvm-build` costs ~3.4G of disk.
- If a build complains the LLVM slice is missing, refresh the canonical copy
  once: `cd ~/repos/jaseci/jac && zig build fetch-llvm` (range-fetch, ~84 MB).
- All local trees pin the same slice (`LLVM-22.1.8-*`). If you bump llvm pins
  in this tree, mirror them in `~/repos/jaseci/jac` so the shared copy is
  refreshed, or pass `-Dllvm-dir` to the build explicitly.
