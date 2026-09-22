"""List a CAB archive."""
def list_cab(
    archive: str, compression: str, cmd: str, verbosity: int, interactive: bool
) -> list[str] {
    _ = compression;
    _ = interactive;
    cmdlist = [cmd, '-l'];
    if verbosity > 0 {
        cmdlist.append('-v');
    }
    cmdlist.append(archive);
    return cmdlist;
}