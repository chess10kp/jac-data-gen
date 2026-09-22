"""Helper Script to get operating systems."""
def get_operating_systems(_os: str | None) -> list[str] {
    if _os {
        return [_os];
    }
    return ["asa", "ios", "iosxe"];
}