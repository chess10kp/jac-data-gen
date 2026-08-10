"""Adds whitespaces around symbols."""
def add_whitespaces(file_contents: str, symbols: list[str]) -> str {
    for symbol in symbols {
        if symbol in file_contents {
            file_contents = file_contents.replace(symbol, " " + symbol + " ");
        }
    }
    return file_contents;
}