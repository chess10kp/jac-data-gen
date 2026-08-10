"""Adjust release_name to match the build version from the executable."""
def adjust_release_version(release_name: str) -> str {
    if release_name.startswith('jdk8u') {
        return release_name.replace('jdk8u', '1.8.0_');
    }
    return release_name[4:];
}