"""
    Creates a dict, where k = the user-created tag names, like 'life',
    v = db column names, like 'tag1'}
    """
def find_tag_column_pairs(tags: list[object]) -> dict[str, str] {
    all_tag_columns: dict[str, str] = {};
    for (counter, tag) in enumerate(tags, start=1) {
        all_tag_columns[str(tag)] = "tag" + str(counter);
    }
    return all_tag_columns;
}