glob BYTE_SUFFIX = "B";
glob BYTE_UNITS = ["", "K", "M", "G", "T", "P", "E", "Z"];

"""
    Cast a number of bytes to a readable string
    >>> from autofaiss.utils.cast import cast_bytes_to_memory_string
    >>> cast_bytes_to_memory_string(16.*1024*1024*1024) == "16.0GB"
    True
    """
def cast_bytes_to_memory_string(num_bytes: float) -> str {
    for unit in BYTE_UNITS {
        if abs(num_bytes) < 1024.0 {
            return "%3.1f%s%s" % (num_bytes, unit, BYTE_SUFFIX);
        }
        num_bytes /= 1024.0;
    }
    return "%.1f%s%s" % (num_bytes, "Y", BYTE_SUFFIX);
}