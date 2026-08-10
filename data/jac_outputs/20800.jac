"""Create a test_fold array for the PredefinedSplit function."""
def generate_predefined_split(n: int = 87, n_sessions: int = 3) -> list[int] {
    test_fold = [];
    for s in range(n_sessions) {
        test_fold.extend([s] * n);
    }
    return test_fold;
}