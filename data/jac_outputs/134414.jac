"""Changes "Something like this" to "something_like_this"."""
def to_underscore_style(text: str) -> str {
    text = text.lower().replace(" ", "_").replace("-", "_");
    return "".join(
        x
        for x in text
        if x.isalpha() or x.isdigit() or x == "_"
    );
}