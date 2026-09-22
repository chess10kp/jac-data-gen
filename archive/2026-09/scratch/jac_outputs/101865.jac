"""Get the root name of a Python simulation."""
def get_root_name(fp: str) -> tuple[str, str] {
    if `type(fp) is not str {
        raise TypeError(
            "expected a string as input for the file path, not whatever you put"
        );
    }
    dot = fp.rfind(".");
    slash = fp.rfind("/");
    `root = fp[(slash + 1):dot];
    fp = fp[:(slash + 1)];
    if fp == "" {
        fp = "./";
    }
    return (`root, fp);
}