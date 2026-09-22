"""Validate crop size and center against image dimensions."""
def validate_input(crop_size: tuple[int, int], crop_center: tuple[int, int]) -> bool {
    distance = 20;
    (x, y) = crop_center;
    (dx, dy) = crop_size;
    (dx, dy) = (dx // 2, dy // 2);
    (dimx, dimy) = (100, 100);
    if any(
        margin < distance
        for margin in [x - dx, dimx - (x + dx + 1), y - dy, dimy - (y + dy + 1)]
    ) {
        return False;
    }
    return True;
}