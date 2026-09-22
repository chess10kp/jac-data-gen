"""
    Replace the key with the read ID instead of file line number
    to make sure joins are correct.
"""
def replace_key_with_read_id(x: tuple[int, list]) -> tuple[int, list] {
    return (x[1][0], x[1]);
}