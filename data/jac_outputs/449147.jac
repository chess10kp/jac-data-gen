"""Compare two version parts and return the difference."""
def compare_version_part(a_part: str, b_part: str) -> int {
    try {
        a_bits = a_part.split('-');
        b_bits = b_part.split('-');
        version_difference = int(a_bits[0]) - int(b_bits[0]);
        if version_difference != 0 or (len(a_bits) == 1 and len(b_bits) == 1) {
            return version_difference;
        }
        if len(a_bits) != len(b_bits) {
            return len(b_bits) - len(a_bits);
        }
        a_letter = a_bits[1][0];
        b_letter = b_bits[1][0];
        if a_letter != b_letter {
            return 0;
        }
        a_number_start = [char.isdigit() for char in a_bits[1]].index(True);
        b_number_start = [char.isdigit() for char in b_bits[1]].index(True);
        return int(a_bits[1][a_number_start:]) - int(b_bits[1][b_number_start:]);
    } except ValueError {
        return 0;
    }
}