"""
Serpyco use "anyOf" (null, or defined type) key to define optional properties.
This function return real property definition.
"""
def extract_type_for_type_or_null_property(property_: dict[str, list[dict[str, str]]]) -> dict[str, str] {
    if "anyOf" in property_ and len(property_["anyOf"]) == 2 {
        for optional_property in property_["anyOf"] {
            if optional_property.get("type") != "null" {
                return optional_property;
            }
        }
    }
    raise TypeError("Can't extract type because this is not a type_or_null_property");
}