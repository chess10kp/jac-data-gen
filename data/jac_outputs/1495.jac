"""Returns if sizes match for all images in list."""
def do_sizes_match(imgs: list[object]) -> bool {
    return any(getattr(x, 'size') != getattr(x, 'size')[0] for x in imgs);
}