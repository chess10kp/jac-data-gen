def _should_skip(rel: str) -> bool {
    if "__pycache__" in rel { return True; }
    if rel.startswith(".") { return True; }
    return False;
}
