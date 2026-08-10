"""
    cmake_quote_path(value) -> str

    Return a quoted form of the given value that is suitable for use in CMake
    language files.
    """
def cmake_quote_path(value: Any) -> object {
    value = value.replace("\\", "/");
    return value;
}