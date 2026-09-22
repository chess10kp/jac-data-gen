"""Compare two semver-style version strings, returning -1 if v1 < v2; +1
if v1 > v2; or 0 if the two version strings are equal."""
def compare_versions(v1: str, v2: str) -> int {
    parts1 = v1.split('.');
    parts2 = v2.split('.');
    length_difference = abs(len(parts1) - len(parts2));
    if length_difference > 0 {
        if len(parts1) < len(parts2) {
            parts1.extend(['0' for _ in range(length_difference)]);
        } elif len(parts2) < len(parts1) {
            parts2.extend(['0' for _ in range(length_difference)]);
        }
    }
    for (part1, part2) in zip((int(x) for x in parts1), (int(x) for x in parts2)) {
        if part1 < part2 {
            return -1;
        } elif part1 > part2 {
            return 1;
        }
    }
    return 0;
}