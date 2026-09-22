"""Convert a dictionary of values into a Vega dataset (array of data elements)."""
def dict_to_vega_dataset(data_dict: dict[str, object]) -> list[dict[str, object]] {
    return [
        {'label': id, 'values': val if isinstance(val, list) else [val]}
        for (id, val) in data_dict.items()
    ];
}