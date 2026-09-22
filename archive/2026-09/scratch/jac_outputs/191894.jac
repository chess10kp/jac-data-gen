"""returns the number of mismatches between strings"""
def get_hamming_mismatch(genome1: str, genome2: str) -> int {
    return sum(1 for (idx, _) in enumerate(genome1) if genome1[idx] != genome2[idx]);
}