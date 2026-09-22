"""Concatenates all entries of a dictionary (lists of strings), in optionally specified order."""
def concatStrDict(d: dict[str, list[list[str]]], order: list[str] = []) -> str {
    retstr = "";
    if d != {} {
        if order == [] {
            order = list(d.keys());
        }
        for key in order {
            itemlist = d[key];
            for strlist in itemlist {
                retstr += "".join(strlist);
            }
        }
    }
    return retstr;
}