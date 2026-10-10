Writing a disk-usage analyzer for backup snapshots, Jac graph style. In `diskmap.jac`:

- `node Folder { name: str }` and `node File { name: str, size: int }` (size in bytes)
- containment is a plain untyped edge: `folder ++> child` where the child is a Folder or a File

Walkers to spawn on a `Folder` (each reports a single value):

1. `DiskUsage` — total bytes of every file anywhere under the folder.
2. `LargeFiles` (`has min_size: int`) — every file under the folder with size >= min_size, as path strings starting at the folder the walker was spawned on and joined with `/`, e.g. `"home/docs/cv.pdf"`. Sort biggest first; ties by path alphabetically.
3. `ExtensionCounts` — a dict mapping lowercase extension (text after the last dot, without the dot) to number of files; files without a dot count under `""`. A leading-dot name like `.bashrc` has no extension either.
