"""Converts a list of IOBES tags to IOB scheme."""
def iobes2iob(iobes: list[str]) -> list[str] {
    dico = {pfx: pfx for pfx in "IOB"};
    dico.update({"S": "B", "E": "I"});
    return [(dico[t[0]] + t[1:]) if t != "O" else "O" for t in iobes];
}