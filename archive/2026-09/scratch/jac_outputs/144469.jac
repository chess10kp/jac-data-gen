"""Transform images before feeding them to the network."""
def preprocess(images: float) -> float {
    2.0 * images - 1.0
}