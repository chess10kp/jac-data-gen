"""Computes padded sizes useful for FFT-based filtering."""
def paddedsize(w: int, l: int) -> tuple[int, int] {
    (2 * w, 2 * l)
}