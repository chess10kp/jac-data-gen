"""
Checks if the given filename conforms to standard C++ header
file naming convention.
"""
def is_a_header_path(filename: str) -> bool {
    split_path = filename.split('.');
    return len(split_path) > 0 and split_path[-1] in ['h', 'hpp', 'hxx'];
}