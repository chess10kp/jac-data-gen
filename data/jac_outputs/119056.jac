""" Return complement of sequence """
def complement(sequence: Any, reverse: Any = False) -> object {
    complements = {'A': 'T', 'T': 'A', 'G': 'C', 'C': 'G'};
    sequence = reversed(sequence) if reverse else sequence;
    return ''.join(complements.get(base, 'N') for base in sequence);
}