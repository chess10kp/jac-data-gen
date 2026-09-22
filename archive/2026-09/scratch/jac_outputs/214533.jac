"""Replace hard tabs with 4 spaces."""
def normalize_raw(raw_line: str) -> str {
    return raw_line.replace('\t', '    ');
}