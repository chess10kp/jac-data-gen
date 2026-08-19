sem search_products = "Search products in the catalog and return matching records.";
sem search_products.query = "Search terms";
sem search_products.category = "Optional category filter";
sem search_products.max_results = "Maximum number of results (default 10)";
def search_products(query: str, category: str = "", max_results: int = 10) -> list[dict] {
    # Implementation
}
