"""Verify two numeric (0s and 1s) representations of images."""
def verify(str1: str, str2: str) -> float | int {
    if len(str1) == len(str2) {
        matches = 0;
        misses = 0;
        for (i, _) in enumerate(str1) {
            if str1[i] == str2[i] {
                matches += 1;
            } else {
                misses += 1;
            }
        }
        return (matches * 100) / len(str1);
    }
    print('Lists with different sizes. Aborting...');
    return -1;
}