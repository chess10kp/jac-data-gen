"""Used to calculate the ratio of the x and y axis of the image to the screen size."""
def get_cursor_ratio(image_size: tuple[int, int], screen_size: tuple[int, int]) -> tuple[float, float] {
    return (screen_size[0] / image_size[0], screen_size[1] / image_size[1]);
}