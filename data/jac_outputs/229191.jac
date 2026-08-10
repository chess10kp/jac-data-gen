"""Removes object_to_be_removed in list if it exists and returns list with removed items."""
def remove_all(original_list: list[int | str | float | bool], object_to_be_removed: int | str | float | bool) -> list[int | str | float | bool] {
    [i for i in original_list if i != object_to_be_removed]
}