"""Ensure that all annotations are in the image and start at pixel 1 at a minimum."""
def check_bbox_in_image(bbox: list[float], img_shape: tuple[int, int, int]) -> list[float] {
    for i in range(len(bbox)) {
        if bbox[i] <= 1.0 {
            bbox[i] = 1.0;
        }
    }
    if bbox[2] >= img_shape[1] {
        bbox[2] = img_shape[1] - 1;
    }
    if bbox[3] >= img_shape[0] {
        bbox[3] = img_shape[0] - 1;
    }
    return bbox;
}