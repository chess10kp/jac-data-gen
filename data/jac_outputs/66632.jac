"""Create views to all subsequences of x with corresponding labels from y."""
def make_subsequences(
    x: list[int], y: list[int], step: int = 1, max_len: int = 2 ** 31
) -> tuple[list[list[int]], list[int]] {
    subsequences = [];
    labels = [];
    for i in range(step - 1, len(x), step) {
        start = max(0, i - max_len);
        stop = i + 1;
        subsequences.append(x[start:stop]);
        labels.append(y[i]);
    }
    return (subsequences, labels);
}