"""Parse nuclide strings like '241Pu' or 'Pu241' into 'Pu-241' format."""
def parse_nuclide_str(nuclide: str) -> str {
    (letter_flag, number_flag) = (False, False);
    for char in nuclide {
        if char.isalpha() {
            letter_flag = True;
        }
        if char.isdigit() {
            number_flag = True;
        }
        if letter_flag and number_flag {
            break;
        }
    }
    if not letter_flag or not number_flag or len(nuclide) < 2 or len(nuclide) > 7 {
        raise ValueError(f"{nuclide} is not a valid nuclide string.");
    }
    while nuclide[0].isdigit() {
        nuclide = nuclide[1:] + nuclide[0];
    }
    if nuclide[0] in ('m', 'n') {
        nuclide = nuclide[1:] + nuclide[0];
    }
    for idx in range(1, len(nuclide)) {
        if nuclide[idx].isdigit() {
            if nuclide[idx - 1] != '-' {
                nuclide = f"{nuclide[:idx]}-{nuclide[idx:]}";
            }
            break;
        }
    }
    return nuclide;
}