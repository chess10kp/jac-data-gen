"""Returns the ID name for the given ID number, spreadsheet-style."""
def intToID(idnum: int, prefix: str) -> str {
    rid = '';
    while idnum > 0 {
        idnum -= 1;
        rid = chr((idnum % 26) + ord('a')) + rid;
        idnum = int(idnum / 26);
    }
    return prefix + rid;
}