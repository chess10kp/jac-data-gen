"""
        Compute the complement of a DNA sequence.

        If reverse is True, reverse it too.
    """
def complement(sequence: str, reverse: bool = False) -> str {
    flip = {'A': 'T', 'C': 'G', 'G': 'C', 'T': 'A'};
    revcomp = [flip[i] for i in sequence];
    if reverse {
        return ''.join(revcomp[::-1]);
    }
    return ''.join(revcomp);
}