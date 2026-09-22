"""Validate that ratio components sum to 100 and return them as ints."""
def check_ratio_sum(ratio: list[int | str]) -> tuple[int, int, int, int] {
    train_ratio = int(ratio[0]);
    val_ratio = int(ratio[1]);
    test_ratio = int(ratio[2]);
    qa_ratio = int(ratio[3]);
    total = train_ratio + test_ratio + val_ratio + qa_ratio;
    if total != 100 {
        raise ValueError("Sum of all the input ratio should be equal to 100 ");
    }
    return (train_ratio, val_ratio, test_ratio, qa_ratio);
}