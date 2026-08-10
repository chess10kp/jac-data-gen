"""Count the number of each nucleotide in the given DNA string."""
def get_nucleotide_count(dna: str) -> tuple[int, int, int, int] {
    (a, c, g, t) = (0, 0, 0, 0);
    for char in dna {
        val = char.upper();
        if val == 'A' {
            a += 1;
        } elif val == 'C' {
            c += 1;
        } elif val == 'G' {
            g += 1;
        } elif val == 'T' {
            t += 1;
        }
    }
    return (a, c, g, t);
}