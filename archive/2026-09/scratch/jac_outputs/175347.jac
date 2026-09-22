"""Get frequency weighted intersection over union."""
def get_frequency_weighted_iou(n: dict[int, dict[int, int]]) -> float {
    k = len(n[0]);
    t = [sum(n[i][j] for j in range(k)) for i in range(k)];
    a = sum(t) ** -1;
    b = sum(
        (t[i] * n[i][i]) / ((t[i] - n[i][i]) + sum(n[j][i] for j in range(k)))
        for i in range(k)
    );
    return a * b;
}