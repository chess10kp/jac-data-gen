def readableSize(byteSize: int, floating: int = 2, binary: bool = True) -> str:
    """Convert bytes to human-readable string (like `-h` option in POSIX).

    Args:
        size (int): Total bytes.
        floating (int, optional): Floating point length. Defaults to 2.
        binary (bool, optional): Format as XB or XiB. Defaults to True.

    Returns:
        str: Human-readable string of size.
    """
    size = float(byteSize)
    unit = "B"
    if binary:
        for unit in ["B", "kiB", "MiB", "GiB", "TiB", "PiB"]:
            if size < 1024.0 or unit == "PiB":
                break
            size /= 1024.0
        return f"{size:.{floating}f}{unit}"
    for unit in ["B", "kB", "MB", "GB", "TB", "PB"]:
        if size < 1000.0 or unit == "PB":
            break
        size /= 1000.0
    return f"{size:.{floating}f}{unit}"

assert readableSize(1024 ** 5) == "1.00PiB"
assert readableSize(1234567890) == "1.15GiB"
assert readableSize(1000) == "1000.00B"
assert readableSize(1000, 10) == "1000.0000000000B"
assert readableSize(4398046511104, 2) == "4.00TiB"
assert readableSize(4096) == "4.00kiB"
assert readableSize(1234567890, 0) == "1GiB"
assert readableSize(100, 1) == "100.0B"
assert readableSize(0, 10) == "0.0000000000B"
assert readableSize(2048) == "2.00kiB"
assert readableSize(0, 2) == "0.00B"
assert readableSize(1024**5) == "1.00PiB"
assert readableSize(0, 5) == "0.00000B"
assert readableSize(1024**3) == "1.00GiB"
assert readableSize(0, 0) == "0B"
assert readableSize(123456789, 1) == "117.7MiB"
assert readableSize(2097152) == "2.00MiB"
assert readableSize(1024) == "1.00kiB"
assert readableSize(1024 ** 3) == "1.00GiB"
assert readableSize(1048576) == "1.00MiB"
assert readableSize(1024 ** 4) == "1.00TiB"
assert readableSize(123456789) == "117.74MiB"
assert readableSize(100, 0) == "100B"
assert readableSize(10, 10) == "10.0000000000B"
assert readableSize(1024**4) == "1.00TiB"
assert readableSize(40, 2) == "40.00B"
assert readableSize(1024**2) == "1.00MiB"
assert readableSize(1) == "1.00B"
assert readableSize(1024 ** 2) == "1.00MiB"
assert readableSize(8192) == "8.00kiB"
assert readableSize(4095) == "4.00kiB"
assert readableSize(1024, 2, False) == "1.02kB"
assert readableSize(1234567890, 0, False) == "1GB"
assert readableSize(1025) == "1.00kiB"
assert readableSize(100, 2) == "100.00B"
assert readableSize(1536) == "1.50kiB"
assert readableSize(100) == "100.00B"
