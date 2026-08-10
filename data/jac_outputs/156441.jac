"""Whether a shape is from an image."""
def is_img_shape(shape: list[int] | tuple[int, ...]) -> bool {
    try {
        return len(shape) == 3 and shape[-3] in (1, 3);
    } except TypeError {
        return False;
    }
}