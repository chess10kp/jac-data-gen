glob KB = 1024;
glob MB = 1048576;
glob GB = 1073741824;

"""Convert a human-readable str representation to number of bytes.

Only the units "kB", "MB", "GB" are supported. The "B character at the end
of the input str may be omitted.
"""
def parse_readable_size_str(size_str: str) -> int {
    size_str = size_str.strip();
    if size_str.endswith("B") {
        size_str = size_str[:-1];
    }
    if size_str.isdigit() {
        return int(size_str);
    } elif size_str.endswith("k") {
        return int(float(size_str[:-1]) * KB);
    } elif size_str.endswith("M") {
        return int(float(size_str[:-1]) * MB);
    } elif size_str.endswith("G") {
        return int(float(size_str[:-1]) * GB);
    } else {
        raise ValueError(
            ("Failed to parsed human-readable byte size str: \"%s\"" % size_str)
        );
    }
}