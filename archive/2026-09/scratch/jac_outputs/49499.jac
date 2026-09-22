"""Create a new dictionary swapping keys and values."""
def invert_dict(input_dict: dict[int, list[str]], sort_keys: bool = False) -> dict[str, int] {
    new_dict = {el: x for x in input_dict for el in input_dict[x]};
    if sort_keys {
        return {el: new_dict[el] for el in sorted(new_dict)};
    }
    return new_dict;
}