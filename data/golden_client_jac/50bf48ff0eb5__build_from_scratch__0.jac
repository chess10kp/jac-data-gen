def _lang_label(rel: str) -> str {
    ext = rel.rsplit(".", 1)[-1].lower();
    return _LANG.get(ext, ext.upper());
}
