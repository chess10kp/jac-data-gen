"""
    Return a tuple of the category and name for a given id
    """
def find_category_name(id: Any, categories: Any) -> object {
    for c in categories {
        for i in categories[c] {
            if (i == id) {
                return (c, categories[c][i]);
            }
        }
    }
}