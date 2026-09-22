"""Determine empirically good embedding sizes (formula taken from fastai)."""
def get_embedding_size(n: int, max_size: int = 100) -> int {
    if n > 2 {
        return min(round(1.6 * (n ** 0.56)), max_size);
    } else {
        return 1;
    }
}