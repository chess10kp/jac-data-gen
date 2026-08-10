"""Writes the basis function term with the given index."""
def writeTerm(index: int) -> str {
    coeffs = [];
    eqtn = "";
    term_index = 0;
    for i in range(1, 9) {
        for j in range(1, 13) {
            term_index += 1;
            coeffs.append([i, j / 8.0, 0]);
            if index == term_index {
                eqtn = eqtn + (" %s^%d * %s^%.3f" % ("D", i, "T", j / 8.0));
            }
        }
    }
    for i in range(1, 6) {
        for j in range(1, 24) {
            term_index += 1;
            coeffs.append([i, j / 8.0, 1]);
            if index == term_index {
                eqtn = eqtn + (" %s^%d * %s^%.3f * exp(-D^1)" % ("D", i, "T", j / 8.0));
            }
        }
    }
    for i in range(1, 6) {
        for j in range(1, 30) {
            term_index += 1;
            coeffs.append([i, j / 8.0, 2]);
            if index == term_index {
                eqtn = eqtn + (" %s^%d * %s^%.3f * exp(-D^2)" % ("D", i, "T", j / 8.0));
            }
        }
    }
    for i in range(2, 5) {
        for j in range(24, 38) {
            term_index += 1;
            coeffs.append([i, j / 2.0, 3]);
            if index == term_index {
                eqtn = eqtn + (" %s^%d * %s^%.3f * exp(-D^3)" % ("D", i, "T", j / 8.0));
            }
        }
    }
    return eqtn;
}