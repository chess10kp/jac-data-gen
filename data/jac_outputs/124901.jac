"""Extract unique category ids from a list of items."""
def extract_catids(all_items: list[dict[str, str | int | float | bool | None]]) -> list[str | int | float] {
    category_ids = list();
    for item in all_items {
        if 'category_id' in item {
            if item['category_id'] not in category_ids and item['category_id'] {
                category_ids.append(item['category_id']);
            }
        }
    }
    return category_ids;
}