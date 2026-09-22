"""Computes the number of input and output units for a weight shape."""
def _compute_fans(shape: list[int]) -> tuple[int | float, int | float] {
    fan_in: int | float = 1;
    fan_out: int | float = 1;
    if len(shape) < 1 {
        fan_in = fan_out = 1;
    } elif len(shape) == 1 {
        fan_in = fan_out = shape[0];
    } elif len(shape) == 2 {
        fan_in = shape[0];
        fan_out = shape[1];
    } else {
        receptive_field_size = 1.0;
        for dim in shape[:-2] {
            receptive_field_size *= dim;
        }
        fan_in = shape[-2] * receptive_field_size;
        fan_out = shape[-1] * receptive_field_size;
    }
    return (fan_in, fan_out);
}