"""Convert elements of a list to integers."""
def turn_list_to_int(list_: list[str | int | float]) -> list[int] {
    return [int(i) for i in list_];
}