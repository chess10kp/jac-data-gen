"""Remove carriage return characters from each element in a list."""
def remove_carriage_ret(lst: list[str]) -> list[str] {
    return [el.replace('\r', '') for el in lst];
}