"""
	Checks if given string can be used as a pixel value for height or width.
	Height or Width or assumed to never surpass 10000
	"""
def validate_pixels(pixels: str | int) -> bool {
    try {
        pixels = int(pixels);
    } except Exception as e {
        return False;
    }
    return 0 < pixels < 10000;
}