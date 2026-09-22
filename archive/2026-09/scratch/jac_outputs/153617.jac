"""given the value and its type, dump it to a dict
		the helper function to dump values into dict ast
	"""
def value_to_dict(val: int | str | float | bool, val_type: str) -> dict[str, str | int | float | bool] {
    return {"type": val_type, "value": val};
}