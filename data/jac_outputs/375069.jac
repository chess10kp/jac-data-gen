"""Strip multiple consecutive newlines from a document."""
def remove_multiple_newlines(content: str) -> str {
    flt = content;
    flt = flt.replace('\n\n\n\n', '\n');
    flt = flt.replace('\n\n\n', '\n');
    flt = flt.replace('\n\n', '\n');
    return flt;
}