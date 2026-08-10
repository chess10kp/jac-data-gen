"""Extract the content without the metadata."""
def extract_content(last_metadata_line: int, raw_content: str) -> str {
    lines = raw_content.split("\n");
    return "\n".join(lines[last_metadata_line + 1:]);
}