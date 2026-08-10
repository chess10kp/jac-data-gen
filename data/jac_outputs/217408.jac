"""Count the number of atoms of each element in a residue."""
def _countResidueAtoms(elements: list[str]) -> dict[str, int] {
    counts: dict[str, int] = {};
    for element in elements {
        if element in counts {
            counts[element] += 1;
        } else {
            counts[element] = 1;
        }
    }
    return counts;
}