"""Compare two x.x.x.x version strings.

Returns -1 if version_1 is higher, 0 if equal, 1 if lower."""
def compare_versions(version_1: str, version_2: str) -> int {
    if not version_1 {
        return 1;
    }
    version_1 = version_1.strip('v');
    version_2 = version_2.strip('v');
    version_1_split = version_1.split('.');
    version_2_split = version_2.split('.');
    for i in range(len(version_1_split)) {
        if version_1_split[i] < version_2_split[i] {
            return 1;
        } elif version_1_split[i] > version_2_split[i] {
            return -1;
        }
    }
    return 0;
}