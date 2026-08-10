"""Count the # of differences between equal length strings str1 and str2"""
def hamming_str(str1: str, str2: str) -> int {
    diffs = 0;
    for (ch1, ch2) in zip(str1, str2) {
        if ch1 != ch2 {
            diffs += 1;
        }
    }
    return diffs;
}