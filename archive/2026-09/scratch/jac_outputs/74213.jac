"""Given a dictionary of keys with related values, return the entry with the highest value."""
def get_max(dic: dict[str, int]) -> dict[str, int] | None {
    if len(dic.items()) == 0 {
        return None;
    }
    (max_item, max_value) = list(dic.items())[0];
    for elem in dic {
        if dic[elem] > max_value {
            max_value = dic[elem];
            max_item = elem;
        }
    }
    return {max_item: max_value};
}