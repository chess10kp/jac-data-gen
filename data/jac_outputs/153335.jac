"""Parse a DB xref string like HGNC:5|MIM:138670 to a dictionary"""
def parseDBXrefs(xrefs: Any) -> object {
    if (xrefs == "-") {
        return {};
    }
    return `dict(
        [
            (xrefParts[0], xrefParts[2])
            for xrefParts in (xref.partition(":") for xref in xrefs.split("|"))
        ]
    );
}