"""Right-zero-pad short-form angle strings with zeros.

    This reduces amount of error checking required, and makes decimal conversions more consistent.
    This will also make the IOD/UK/RDE angle lengths uniform (UK/RDE adds one more digit of precision on the right)."""
def right_zero_pad(val: str, length: int = 8) -> str {
    val = val.rstrip();
    val + ("0" * (length - len(val)))
}