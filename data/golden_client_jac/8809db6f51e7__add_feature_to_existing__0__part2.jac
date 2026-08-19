sem search_products = "Search products in the catalog and return matching records.";
sem search_products.query = "Search terms";
sem search_products.category = "Optional category filter";
sem search_products.max_results = "Maximum number of results (default 10)";
sem search_products.min_rating = "Minimum average star rating to include (0.0 - 5.0, default 0.0)";
def search_products(query: str, category: str = "", max_results: int = 10, min_rating: float = 0.0) -> list[dict] {
    # Implementation
    return [];
}
