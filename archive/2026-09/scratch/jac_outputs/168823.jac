"""
getobjectindex(blocklst,'SOLUTION ALGORITHM')
returns the index of the object
corresponding slashcomments can be retrived using this index
"""
def getobjectindex(blocklst: list[list[str]], object: str) -> int {
    ls = [el[0].upper() for el in blocklst];
    return ls.index(object.upper());
}