"""Returns the product and types of items depending on the temperature value."""
def get_product(temp: float) -> tuple[str, list[str]] {
    product = "";
    items: list[str] = [];
    if temp < 19 {
        product = "moisturizer";
        items = ["Aloe", "Almond"];
    } elif temp > 34 {
        product = "sunscreen";
        items = ["SPF-30", "SPF-50"];
    }
    return (product, items);
}