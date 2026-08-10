"""Get all ids out of a list of objects and return a list of string ids."""
def get_ids_from_list_of_dicts(lst: list[dict[str, str]]) -> list[str] {
    return [item_dict["id"] for item_dict in lst if "id" in item_dict];
}