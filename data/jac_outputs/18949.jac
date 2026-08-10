"""Convert model coordinates format to (xmin,ymin,width,height)."""
def get_box_coordinates(box: list[float], img_shape: list[int]) -> tuple[int, int, int, int] {
    (height, width) = img_shape[:2];
    xmin = max(int(box[1] * width), 0);
    ymin = max(int(box[0] * height), 0);
    xmax = min(int(box[3] * width), width - 1);
    ymax = min(int(box[2] * height), height - 1);
    return (xmin, ymin, xmax - xmin, ymax - ymin);
}