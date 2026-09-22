"""Alternate string representation of element of Wall's basis."""
def wall_long_mono_to_string(mono: tuple[tuple[int, int], ...], latex: bool = False) -> str {
    sq = "\\text{Sq}" if latex else "Sq";
    if len(mono) == 0 {
        return "1";
    }
    string = "";
    for (m, k) in mono {
        for i in range(k, m + 1) {
            string = string + sq + "^{" + str(2 ** i) + "} ";
        }
    }
    return string.strip(" ");
}