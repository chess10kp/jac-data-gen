"""Return string representation for size."""
def get_size_string(size: Any) -> object {
    if (size < (1 << 10)) {
        return ('%d B' % size);
    } elif (size < (1 << 20)) {
        return ('%d KB' % (size >> 10));
    } elif (size < (1 << 30)) {
        return ('%d MB' % (size >> 20));
    }
    return ('%d GB' % (size >> 30));
}