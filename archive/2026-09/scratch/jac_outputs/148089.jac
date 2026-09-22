"""Check the datatype of an object."""
def check_type(item: object, expected_type: str) -> str {
    item_type = str(`type(item));
    expected_lower = expected_type.lower();
    if not (
        ("str" in expected_lower and item_type == "<class 'str'>")
        or ("int" in expected_lower and item_type == "<class 'int'>")
        or ("bool" in expected_lower and item_type == "<class 'bool'>")
        or ("float" in expected_lower and item_type == "<class 'float'>")
        or ("tuple" in expected_lower and item_type == "<class 'tuple'>")
        or ("list" in expected_lower and item_type == "<class 'list'>")
        or ("dict" in expected_lower and item_type == "<class 'dict'>")
        or ("datetime" in expected_lower and item_type == "<class 'datetime.datetime'>")
        or ("none" in expected_lower and item_type == "<class 'NoneType'>")
    ) {
        raise TypeError("{a} isn't a {b}".format(a=object, b=expected_type));
    }
    return item_type;
}