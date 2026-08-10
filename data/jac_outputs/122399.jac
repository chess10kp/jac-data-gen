"""Splits a string containing a file name into the filename and extension"""
def split_filename(name: str) -> tuple[str, str] {
    dot = name.rfind('.');
    if dot == -1 {
        return (name, '');
    }
    return (name[:dot], name[dot + 1:]);
}