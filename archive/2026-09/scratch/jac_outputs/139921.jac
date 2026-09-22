"""Reverse complement a DNA sequence."""
def reverse_complement(seq: str) -> str {
    complement = {
        'A': 'T', 'T': 'A', 'G': 'C', 'C': 'G',
        'a': 't', 't': 'a', 'g': 'c', 'c': 'g'
    };
    return ''.join([complement[b] for b in seq[::-1]]);
}