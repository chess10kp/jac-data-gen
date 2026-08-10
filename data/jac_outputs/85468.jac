"""Removes all duplicated values from the supplied list."""
def make_list_unique(elem_list: list[int | str]) -> list[int | str] {
    list(dict.fromkeys(elem_list))
}