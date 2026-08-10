"""Return the output shape for squared root normalization layer for any given input size."""
def squared_root_normalization_output_shape(input_shape: tuple[int, ...]) -> tuple[int, int] {
    return (input_shape[0], input_shape[-1]);
}