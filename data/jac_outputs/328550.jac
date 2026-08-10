"""Returns object with net specs."""
def net_specs(
    name: str, input_shape: list[int], num_classes: int, dtype: str = 'float'
) -> dict[str, str | int | list[int]] {
    return {
        'name': name,
        'input_shape': input_shape,
        'num_classes': num_classes,
        'dtype': dtype
    };
}