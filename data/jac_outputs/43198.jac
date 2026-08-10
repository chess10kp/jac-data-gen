"""Return contents of docstring."""
def strip_docstring(docstring: str) -> str {
    docstring = docstring.strip();
    quote_types = ["'''", '"""', "'", '"'];
    for quote in quote_types {
        if docstring.startswith(quote) and docstring.endswith(quote) {
            return docstring.split(quote, 1)[1].rsplit(quote, 1)[0].strip();
        }
    }
    raise ValueError('We only handle strings that start with quotes');
}