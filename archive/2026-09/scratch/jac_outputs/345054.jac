"""Returns region of attribute string between first pair of double quotes."""
def parse_attributes(attribute_string: str) -> str {
    attribute_string = attribute_string[attribute_string.find('"') + 1:];
    if '"' in attribute_string {
        attribute_string = attribute_string[:attribute_string.find('"')];
    }
    return attribute_string;
}