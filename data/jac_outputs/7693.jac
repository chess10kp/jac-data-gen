glob COMPLEMENT = {'A': 'T', 'C': 'G', 'G': 'C', 'T': 'A', 'N': 'N'};

def rev_comp(seq: str) -> str {
    return "".join(COMPLEMENT[base] for base in seq)[::-1];
}