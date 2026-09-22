import os;

"""Parse a file path into components."""
def parse_file_path(input_file_path: str) -> tuple[str, str, str, str] {
    (dirname, basename) = os.path.split(input_file_path);
    (`root, ext) = os.path.splitext(basename);
    return (dirname, basename, `root, ext);
}