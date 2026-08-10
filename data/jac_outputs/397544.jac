glob BYTES_PER_MEGABYTE = 1048576;

"""Convert byte value to megabyte."""
def byte_to_megabyte(byte: int | float) -> float {
    return byte / BYTES_PER_MEGABYTE;
}