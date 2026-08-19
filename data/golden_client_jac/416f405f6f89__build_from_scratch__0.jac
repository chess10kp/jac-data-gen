def _file_meta(rel: str, size: int) -> dict {
    return {
        "path": rel,
        "name": rel.split("/")[-1],
        "dir": rel.rsplit("/", 1)[0],
        "lang": _lang_label(rel),
        "size": size
    };
}
