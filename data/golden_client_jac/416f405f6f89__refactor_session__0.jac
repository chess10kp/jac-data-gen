def _file_meta(rel: str, size: int) -> dict;

impl _file_meta {
    return {
        "path": rel,
        "name": os.path.basename(rel),
        "dir": os.path.dirname(rel),
        "lang": _lang_label(rel),
        "size": size
    };
}
