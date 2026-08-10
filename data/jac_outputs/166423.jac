"""Parses a VHDL version string or int, 2- or 4-digit style, to a full
    4-digit version identifier integer."""
def _parse_version(version: str | int | None) -> int | None {
    if version is None {
        return None;
    }
    version = int(version);
    if version < 70 {
        version += 2000;
    } elif version < 100 {
        version += 1900;
    }
    return version;
}