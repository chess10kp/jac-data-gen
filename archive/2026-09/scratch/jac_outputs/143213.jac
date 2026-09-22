"""
Pad the collection `coll` with `padding` items
until it reaches the length of `size`.
By default do padding in the beginning (on the left side).
"""
def pad[T](coll: list[T], size: int, padding: T, left: bool = True) -> list[T] {
    padding_size = size - len(coll);
    if padding_size <= 0 {
        return coll;
    }
    pad_items = [padding] * padding_size;
    new_list = list(coll);
    return pad_items + new_list if left else new_list + pad_items;
}