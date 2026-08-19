import from byllm.lib { Image }

"""Search for products matching the description."""
def search_products(query: str) -> list[str] {
    # Simulated product search
    return [f"Product matching '{query}' - $29.99"];
}

"""Look at the image and find similar products."""
def find_similar_products(img: Image) -> str by llm(
    tools=[search_products]
);

with entry {
    product_image = Image("shoe.jpg");
    results = find_similar_products(product_image);
    print(results);
}
