def is_arithmetic_progression(seq: Any) -> object {
    if (len(seq) <= 2) {
        return True;
    }
    diff = seq[1] - seq[0];
    for i in range(2, len(seq)) {
        if ((seq[i] - seq[(i - 1)]) != diff) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_arithmetic_progression([81]));
    print(is_arithmetic_progression([-8, -4, 2]));
}
