"""Computes the precision score of one image."""
def map_per_image(label: str, predictions: list[str]) -> float {
    try {
        return 1 / (predictions[:5].index(label) + 1);
    } except ValueError {
        return 0.0;
    }
}