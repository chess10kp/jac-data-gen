"""Returns True if the text "# Long" is in the first line of raw_python_source. False otherwise."""
def test_for_short_cell(raw_python_source: str) -> bool {
    first_element = raw_python_source.split("\n")[0];
    return "#" in first_element and "short" in first_element.lower();
}