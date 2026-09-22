"""Parse a line like:

    __version__ = '1.0.1'

and return:

    1.0.1
"""
def _parse_dunder(line: str) -> str {
    item = line.split('=')[1].strip();
    item = item.strip('"').strip("'");
    return item;
}