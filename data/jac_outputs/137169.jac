"""
    Question 6.5: Given an array and an input key,
    remove the key from the array
    """
def delete_key(ls: list[int | None], key: int | None) -> list[int | None] {
    write_idx = 0;
    for (idx, elt) in enumerate(ls) {
        if elt != key {
            ls[write_idx] = elt;
            write_idx += 1;
        }
    }
    while write_idx < len(ls) {
        ls[write_idx] = None;
        write_idx += 1;
    }
    return ls;
}