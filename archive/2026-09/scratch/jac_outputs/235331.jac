"""Compare two DNA sequences using DotPlot method."""
def dotPlot(seqA: str, seqB: str) -> list[list[str]] {
    la = len(seqA);
    lb = len(seqB);
    M = [[' ' for _ in range(la)] for _ in range(lb)];
    for i in range(lb) {
        for j in range(la) {
            if seqB[i] == seqA[j] {
                M[i][j] = 'x';
            }
        }
    }
    return M;
}