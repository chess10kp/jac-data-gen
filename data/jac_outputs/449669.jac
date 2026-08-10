"""Retrieves the default extension for a delimiter."""
def get_default_ext(delim: str) -> str {
    if delim == ',' {
        return "csv";
    }
    if delim == '\t' {
        return "tsv";
    }
    return "txt";
}