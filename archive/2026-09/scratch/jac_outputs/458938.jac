def classification_result[T](y: list[T], y_pred: list[T]) -> tuple[list[int], list[int]] {
    assert len(y) == len(y_pred);
    correct: list[int] = [];
    wrong: list[int] = [];
    for (i, _) in enumerate(y) {
        if y[i] == y_pred[i] {
            correct.append(i);
        } else {
            wrong.append(i);
        }
    }
    return (correct, wrong);
}