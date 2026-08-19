def _normalize_rel(rel: str) -> str {
    without_leading = rel.strip("/");
    return without_leading.replace("\\", "/");
}
