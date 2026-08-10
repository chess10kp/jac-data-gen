"""Computes a kmer difference between two strings."""
def kdiff(str1: str, str2: str, k: int = 10) -> float {
    cnt = 0.0;
    for i in range(len(str1) - k) {
        cnt += 1 if str2.find(str1[i:(i + k)]) < 0 else 0;
    }
    return cnt / (len(str1) - k);
}