def _lang_label(rel: str) -> str;

impl _lang_label {
    if rel.endswith(".jac") { return "Jac"; }
    ext = rel.rsplit(".", 1)[-1].lower() if "." in os.path.basename(rel) else "";
    return _LANG.get(ext, ext.upper() or "Text");
}
