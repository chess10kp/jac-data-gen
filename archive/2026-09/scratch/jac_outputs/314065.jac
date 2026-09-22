"""Try meta_ext[key], then fall back to meta_file[key]."""
def get_choice(meta_ext: dict[str, str] | None, meta_file: dict[str, str], key: str) -> str | None {
    assert meta_file is not None;
    if meta_ext is not None {
        ret = meta_ext.get(key, None);
        if ret is None {
            ret = meta_file.get(key);
        }
    } else {
        ret = meta_file.get(key, None);
    }
    return ret;
}