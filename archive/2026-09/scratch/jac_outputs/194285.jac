"""Return the unique elements of a collection even if those elements are
       unhashable and unsortable, like dicts and sets"""
def unique(seq: list[object]) -> list[object] {
    cleaned: list[object] = [];
    for item in seq {
        if item not in cleaned {
            cleaned.append(item);
        }
    }
    return cleaned;
}