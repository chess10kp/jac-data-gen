"""Construct version tag: "major.minor.micro" (or "major.minor.micro-dev" when dev is set)."""
def construct_version_string(
    major: int, minor: int, micro: int, dev: str | None = None
) -> str {
    version_tag = f"{major}.{minor}.{micro}";
    if dev is not None {
        version_tag += f"-{dev}";
    }
    return version_tag;
}