"""Extract the (key,value)-tuple from a string like "option foobar 123"."""
def _extract_prop_option(line: str) -> tuple[str, str] {
    line = line[7:];
    pos = line.find(' ');
    return (line[:pos], line[(pos + 1):]);
}