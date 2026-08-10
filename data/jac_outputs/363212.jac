"""
    Returns reverse complement of seq, with
    any non-ACTG characters replaced with Ns

    """
def reverse_complement(seq: Any) -> object {
    transform = {'A': 'T', 'T': 'A', 'C': 'G', 'G': 'C', 'N': 'N'};
    try {
        comp = [transform[e] for e in seq];
    } except KeyError {
        seq = [e if (e in "ACTGN") else "N" for e in seq];
        comp = [transform[e] for e in seq];
    }
    rev_comp = comp[::-1];
    rev_comp_string = ''.join(rev_comp);
    return rev_comp_string;
}