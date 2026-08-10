"""
Normalize image pixel component values to 0-1 range.
"""
def image_proc_normalize(image: list[list[int | float | list[int | float]]]) -> list[list[float | list[float]]] {
    output_image = [];
    for row in image {
        output_row = [];
        for pixel in row {
            if isinstance(pixel, float) or isinstance(pixel, int) {
                output_row.append(pixel / 255);
            } else {
                output_row.append([(component / 255) for component in pixel]);
            }
        }
        output_image.append(output_row);
    }
    return output_image;
}