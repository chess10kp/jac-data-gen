"""Create a LZH archive."""
def create_lzh(
    archive: str,
    compression: int,
    cmd: str,
    verbosity: int,
    interactive: bool,
    filenames: list[str]
) -> list[str] {
    opts = 'a';
    if verbosity > 1 {
        opts += 'v';
    }
    cmdlist = [cmd, opts, archive];
    cmdlist.extend(filenames);
    return cmdlist;
}