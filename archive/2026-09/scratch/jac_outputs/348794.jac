"""
	Scale the given value from the scale of src to the scale of dst.
	"""
def scale(val: Any, src: Any, dst: Any) -> object {
    return int(
        ((((val - src[0]) / float((src[1] - src[0]))) * (dst[1] - dst[0])) + dst[0])
    );
}