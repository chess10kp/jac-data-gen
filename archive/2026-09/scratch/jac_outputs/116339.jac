"""convert a boolean value to text"""
def ods_bool_value(value: bool) -> str {
    if value is True {
        return "true";
    } else {
        return "false";
    }
}