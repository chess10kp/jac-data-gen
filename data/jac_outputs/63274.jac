"""Get item of list without the risk of an error being thrown."""
def get_list_item[T](lst: list[T], index: int) -> T | None {
    if 0 <= index < len(lst) {
        return lst[index];
    }
    return None;
}