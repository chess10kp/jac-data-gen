"""Return the complement of each nucleotide."""
def rev_seq(nuc: str, nuc_type: str = 'dna') -> str {
    match nuc {
        case 'A':
            if nuc_type == 'rna' {
                return 'U';
            }
            return 'T';
        case 'T':
            return 'A';
        case 'C':
            return 'G';
        case 'U':
            return 'A';
        case _:
            return 'C';
    }
}