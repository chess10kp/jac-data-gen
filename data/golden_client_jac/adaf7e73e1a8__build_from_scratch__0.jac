def _normalize_rel(rel: str) -> str {
    return rel.replace("\\", "/").lstrip("/");
}
