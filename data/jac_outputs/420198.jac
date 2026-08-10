"""Parse a psimitab column field into (xref, value, desc)."""
def parse_field(field_string: str) -> tuple[str, str, str] {
    parts = field_string.split(":");
    xref = parts[0];
    rest = parts[1];
    if "(" in rest {
        subfields = rest.split("(");
        value = subfields[0];
        desc = subfields[1][:-1];
    } else {
        value = rest;
        desc = "NA";
    }
    return (xref, value, desc);
}