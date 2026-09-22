"""0-based system is used (like in Biopython):

    |            INPUT            |          RETURNS            |
    |-----------------------------|-----------------------------|
    |                             |                             |
    |  s1=3      e1=14            |                             |
    |     |----------|            |        [9,14]               |
    |           |---------|       |                             |
    |        s2=9     e2=19       |                             |
    |                             |                             |
    """
def get_overlap_region(s1: int, e1: int, s2: int, e2: int) -> tuple[int | None, int | None] {
    if s1 > e1 or s2 > e2 {
        raise Exception(
            "Something is wrong with the intervals (%i,%i) and (%i,%i)"
            % (s1, e1, s2, e2)
        );
    }
    if s1 <= s2 <= e1 and s1 <= e2 <= e1 {
        return (s2, e2);
    } elif s2 <= s1 <= e2 and s2 <= e1 <= e2 {
        return (s1, e1);
    } elif s1 <= s2 <= e1 and s2 <= e1 <= e2 {
        return (s2, e1);
    } elif s2 <= s1 <= e2 and s1 <= e2 <= e1 {
        return (s1, e2);
    } else {
        return (None, None);
    }
}