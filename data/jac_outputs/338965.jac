glob DNA_COMPLEMENT = {'A': 'T', 'C': 'G', 'G': 'C', 'T': 'A'};

"""Return reverse complement DNA sequence."""
def reverse_complement(dna_sequence: str) -> str {
    complement = [DNA_COMPLEMENT[base] for base in dna_sequence];
    return ''.join(reversed(complement));
}