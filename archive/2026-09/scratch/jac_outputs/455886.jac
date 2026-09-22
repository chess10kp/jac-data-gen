"""Calculate the resulting output shape for an image layer with the specified options."""
def image_output_size(
    input_shape: tuple[int, int, int, int],
    size: list[int],
    stride: tuple[int, int],
    padding: str
) -> tuple[int, int, int, int] {
    if len(size) > 2 and input_shape[3] != size[2] {
        print("Matrix size incompatible!");
    }
    height = size[0];
    width = size[1];
    out_depth = size[3] if len(size) > 2 else int(input_shape[3]);
    input_height = input_shape[1];
    input_width = input_shape[2];
    if padding == "VALID" {
        input_height -= height - 1;
        input_width -= width - 1;
    }
    return (
        int(input_shape[0]),
        (input_height + stride[0] - 1) // stride[0],
        (input_width + stride[1] - 1) // stride[1],
        out_depth
    );
}