def is_archived(filename: str, suffixes: list[str]) -> bool {
    return any(filename.endswith(s) for s in suffixes);
}