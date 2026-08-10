"""Get dict of properties for output module."""
def get_module_properties(properties: list[str]) -> dict[str, str | None] {
    module_props = dict(property=None, derivative=None, contributions=None);
    for prop in properties {
        if prop.startswith("property") {
            module_props["property"] = prop;
        } elif prop.startswith("derivative") {
            module_props["derivative"] = prop;
        } elif prop.startswith("contributions") {
            module_props["contributions"] = prop;
        }
    }
    return module_props;
}