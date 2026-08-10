"""
    Given a list of items and a list of categories and a way to determine if an item fits into a category creates
    lists of items fitting in each category as well as a list of items that fit in no category.
    """
def sort_into_categories(
    items: list[object],
    categories: list[object],
    fit: Callable[[object, object], bool],
    unknown_category_name: object | None = None
) -> dict[object, list[object]] {
    categorized_sublists = {};
    for category in categories {
        sublist = [item for item in items if fit(item, category)];
        categorized_sublists[category] = sublist;
    }
    if unknown_category_name {
        sublist = [item for item in items if not any(fit(item, category) for category in categories)];
        categorized_sublists[unknown_category_name] = sublist;
    }
    return categorized_sublists;
}