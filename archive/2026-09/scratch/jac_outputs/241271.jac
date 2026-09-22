"""Split version string into major1.major2.minor components."""
def version_components(version: str) -> tuple[str, str, str] {
    components = version.split(".");
    num = len(components);
    if num < 1 {
        raise ValueError("version should have at least one component.");
    }
    major1 = components[0];
    major2 = components[1] if num >= 2 else "0";
    minor = components[2] if num >= 3 else "0";
    return (major1, major2, minor);
}