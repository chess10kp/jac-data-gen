""" in:  ["Col1:Text", "Col2:INT"]
        out: {
                 Col1: TEXT,
                 Col2: INT
             }
    """
def get_ctypes(ColumnsNamesType: list[str]) -> dict[str, str] {
    ctypes: dict[str, str] = {};
    for col in ColumnsNamesType {
        splits = col.split(":");
        cname = splits[0];
        ctype = splits[1].upper();
        ctypes[cname] = ctype;
    }
    return ctypes;
}