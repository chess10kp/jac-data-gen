"""Helper method: returns total of string sequence."""
def tot(sequence: str, total: int = 0) -> int {
    total = 0;
    counter = 0;
    temp = '';
    plus_minus = 1;
    while counter < len(sequence) {
        try {
            int(sequence[counter]);
            temp += sequence[counter];
        } except ValueError {
            total += int(temp) * plus_minus;
            temp = '';
            if sequence[counter] == '-' {
                plus_minus = -1;
            }
            if sequence[counter] == '+' {
                plus_minus = 1;
            }
        }
        counter += 1;
    }
    total += int(temp) * plus_minus;
    return total;
}