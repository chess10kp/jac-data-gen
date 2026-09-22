"""Return the reverse complement of the input motif."""
def rev_comp_motif(motif: str) -> str {
    comp = {
        "A": "T",
        "T": "A",
        "C": "G",
        "G": "C",
        "W": "S",
        "S": "W",
        "M": "K",
        "K": "M",
        "R": "Y",
        "Y": "R",
        "B": "V",
        "D": "H",
        "H": "D",
        "V": "B",
        "N": "N",
        "X": "X",
        "*": "*"
    };
    return "".join(comp[char] for char in motif[::-1]);
}