glob COMPLEMENT = {'A': 'T', 'T': 'A', 'C': 'G', 'G': 'C'};

"""Return the complement of the entered DNA sequence."""
def build_complement(base: str) -> str {
    strand = '';
    for ch in base {
        if ch in COMPLEMENT {
            strand += COMPLEMENT[ch];
        }
    }
    return strand;
}