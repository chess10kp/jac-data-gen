"""Map a continuous value to a binary classification by thresholding."""
def get_binary_class(value: float, thresh: float = 4.0) -> int {
    return int(value > thresh);
}