"""Compacts a dct by removing pairs with a None value. Other nil values pass."""
def compact_dict_none(dct: dict[str, str | int | float | bool | None]) -> dict[str, str | int | float | bool] {
    return {k: v for (k, v) in dct.items() if v != None};
}