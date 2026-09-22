"""Replace ambiguous amino acids."""
def simplify_alphabet(sequence: str) -> str {
    return sequence.replace("U", "C");
}