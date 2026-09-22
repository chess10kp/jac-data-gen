"""Arrange a list of strings into columns."""
def fmtcols(mylist: list[str], cols: int) -> str {
    lines = ("\t".join(mylist[i:(i + cols)]) for i in range(0, len(mylist), cols));
    return '\n'.join(lines);
}