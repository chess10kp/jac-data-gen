"""
    Given a class name (e.g. CountryData) return an identifer
    for the data-table for that class.
    """
def make_identifier(classname: str) -> str {
    identifier = [classname[0].lower()];
    for c in classname[1:] {
        if c.isupper() {
            identifier.extend(["_", c.lower()]);
        } else {
            identifier.append(c);
        }
    }
    return "".join(identifier);
}