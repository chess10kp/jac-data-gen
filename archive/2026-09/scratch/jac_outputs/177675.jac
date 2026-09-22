"""Normalizes values in the given dict with int values."""
def norm_int_dict(int_dict: dict[str, int]) -> dict[str, float] {
    val_sum = sum(int_dict.values());
    return {key: int_dict[key] / val_sum for key in int_dict};
}