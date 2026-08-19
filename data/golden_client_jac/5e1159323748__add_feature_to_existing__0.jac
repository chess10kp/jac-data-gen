"""Get a product description."""
def get_description(product: str) -> str {
    return kb["descriptions"].get(product, "No description available");
}
