"""Scale and trim model box coordinates to fit the actual image dimensions."""
def scale_and_trim_boxes(
    boxes: list[list[float]], image_width: int, image_height: int
) -> list[list[int]] {
    scaled_boxes: list[list[int]] = [];
    max_dimension = max(image_width, image_height);
    for box in boxes {
        x_min = max(0, int(box[1] * max_dimension));
        y_min = max(0, int(box[0] * max_dimension));
        x_max = min(image_width, int(box[3] * max_dimension));
        y_max = min(image_height, int(box[2] * max_dimension));
        scaled_boxes.append([x_min, y_min, x_max, y_max]);
    }
    return scaled_boxes;
}