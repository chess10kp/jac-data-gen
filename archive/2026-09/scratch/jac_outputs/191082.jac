"""Accuracy for Root Cause Analysis with multiple causes.
    Refined from the Acc metric in TBAC paper.
    """
def my_acc(scoreList: list[tuple[int, float]], rightOne: list[int], n: int | None = None) -> float {
    node_rank = [_[0] for _ in scoreList];
    if n is None {
        n = len(scoreList);
    }
    s = 0.0;
    for i in range(len(rightOne)) {
        if rightOne[i] in node_rank {
            rank = node_rank.index(rightOne[i]) + 1;
            s += (n - max(0, rank - len(rightOne))) / n;
        }
    }
    s /= len(rightOne);
    return s;
}