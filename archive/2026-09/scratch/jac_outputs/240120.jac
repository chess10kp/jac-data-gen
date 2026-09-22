"""Determine whether the given unix socket path is in a filesystem namespace."""
def _inFilesystemNamespace(path: bytes | str) -> bool {
    return path[:1] not in (b'\x00', "\0");
}