"""
    val is a dictionary
    :param val:
    :return: True/False
    """
def _value_properties_are_referenced(val: Any) -> object {
    if (('properties' in val.keys()) and ('$ref' in val['properties'].keys())) {
        return True;
    }
    return False;
}