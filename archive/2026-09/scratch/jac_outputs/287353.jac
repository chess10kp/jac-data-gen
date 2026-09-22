import from xml.sax.saxutils { escape }

"""Convert an object into its XML-escaped string representation."""
def xml_escape(input: str | None) -> str {
    if input is None {
        return "";
    }
    return escape(input);
}