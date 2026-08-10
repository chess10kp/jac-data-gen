"""Map from replacement to source and reverse each string also.

The string reverse is needed because the steps_to_molecule
reverses the molecule string itself."""
def reverse_reps(replacements: list[tuple[str, str]]) -> dict[str, str] {
    return {b[::-1]: a[::-1] for (a, b) in replacements};
}