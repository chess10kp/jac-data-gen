"""test if object is pathlib.Path like"""
def is_path_like(
    `obj: object,
    attr: tuple[str, str, str, str] = ('name', 'is_file', 'is_dir', 'iterdir')
) -> bool {
    for a in attr {
        if not hasattr(`obj, a) {
            return False;
        }
    }
    True
}