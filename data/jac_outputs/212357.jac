"""Convert a sequence to FASTA format (60 per line)."""
def Fastaline(x: str, **kwargs: int) -> str {
    res = '';
    while len(x) != 0 {
        res += ''.join(x[:60]) + '\n';
        x = x[60:];
    }
    return res;
}