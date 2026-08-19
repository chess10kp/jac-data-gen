import from byllm.lib { Image }

glob catalog: list[str] = ["Red Running Shoe - $29.99", "Blue Sneaker - $34.99", "Leather Boot - $89.99"];

"""Search for products matching the description."""
def search_products(query: str) -> list[str] {
    q = query.lower();
    return [p for p in catalog if q in p.lower()];
}

"""Look at the image and find similar products."""
def find_similar_products(img: Image) -> str by llm(
    tools=[search_products]
);
