"""Map Categories to Numeric Labels"""
def apply_pred_id(x: str | int, labels: dict[str | int, str | int]) -> int {
    try {
        return int(labels[x]);
    } except Exception {
        return -1;
    }
}