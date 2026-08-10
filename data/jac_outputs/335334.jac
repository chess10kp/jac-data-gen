"""extracts facets values from the contents attribute"""
def get_facets_values(facet: str | list[str], header: list[str]) -> dict[str, str] {
    values = {};
    if type(facet) is str {
        values.update({header[0]: facet});
    } elif type(facet) is list {
        values.update({k: v for (k, v) in zip(header, facet)});
    }
    return values;
}