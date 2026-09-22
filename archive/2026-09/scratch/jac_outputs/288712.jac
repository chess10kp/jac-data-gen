"""Get all keys from a value in a dictionary."""
def get_keys_from_val(dic: dict[str, int | str], val: int | str) -> list[str] {
    return [key for key in dic if dic[key] == val];
}