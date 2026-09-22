"""Returns the value of the `-swift-version` argument, if found."""
def collect_swift_version(copts: list[str]) -> str | None {
    last_swift_version = None;
    for (i, copt) in enumerate(copts) {
        if copt == "-swift-version" and i + 1 < len(copts) {
            last_swift_version = copts[i + 1];
        }
    }
    return last_swift_version;
}