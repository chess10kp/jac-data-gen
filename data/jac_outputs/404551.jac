"""Return request string for a single operation to create an attribute of type array/list."""
def create_list_attr_operation(var_attribute_list_name: str) -> str {
    return '{"op":"CreateAttributeValueList","attributeName":"' + var_attribute_list_name + '"},';
}