"""Returns the glyph name until the first dot."""
def firstPartOfGlyphName(name: str) -> str {
    dot_position = name.find(".");
    if dot_position != -1 {
        return name[:dot_position];
    }
    return name;
}