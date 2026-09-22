"""Return a tuple of all the training folds."""
def training_folds(fold: int, k: int = 10) -> tuple[int, ...] {
    assert fold < k;
    tuple(num for num in range(10) if num != fold)
}