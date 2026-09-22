"""Count occurrences of N, S, V, F, and Q across label strings."""
def count_label(SEG_label: list[str]) -> list[int] {
    (N, S, V, F, Q) = (0, 0, 0, 0, 0);
    for label in SEG_label {
        N += label.count('N');
        S += label.count('S');
        V += label.count('V');
        F += label.count('F');
        Q += label.count('Q');
    }
    return [N, S, V, F, Q];
}