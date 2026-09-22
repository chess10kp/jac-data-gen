"""Return a dictionary of package versions."""
def get_package_versions(lines: list[str]) -> dict[str, str] {
    versions = {};
    for line in lines {
        line = line.strip();
        if len(line) == 0 or line.startswith('#') or line.startswith('-r ') {
            continue;
        }
        if line.startswith('https://') {
            continue;
        }
        (name, version_plus) = line.split('==', 1);
        versions[name.lower()] = version_plus.split(' ', 1)[0];
    }
    return versions;
}