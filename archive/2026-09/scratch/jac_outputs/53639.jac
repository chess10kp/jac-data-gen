"""Returns true if the item is visible."""
def is_item_visible(item: dict[str, int]) -> bool {
    for attr in ['is_deleted', 'is_archived', 'in_history', 'checked'] {
        if item[attr] == 1 {
            return False;
        }
    }
    return True;
}