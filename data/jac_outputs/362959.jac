"""Test a RAR archive."""
def test_rar(
    archive: str, compression: str, cmd: str, verbosity: int, interactive: bool
) -> list[str] {
    cmdlist = [cmd, 't'];
    if not interactive {
        cmdlist.extend(['-p-', '-y']);
    }
    cmdlist.extend(['--', archive]);
    return cmdlist;
}