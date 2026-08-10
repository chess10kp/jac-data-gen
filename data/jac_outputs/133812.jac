"""
    Rescale the range of values of `x` from [input_min, input_max] -> [output_min, output_max].
    """
def rescale_values(
    x: Any,
    input_min: Any = -1,
    input_max: Any = 1,
    output_min: Any = 0,
    output_max: Any = 255
) -> object {
    assert (input_max > input_min);
    assert (output_max > output_min);
    return (
        (((x - input_min) * (output_max - output_min)) / (input_max - input_min))
        + output_min
    );
}