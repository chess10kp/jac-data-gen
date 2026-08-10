"""Validate if a key value of a dictionary is a pure numeric string."""
def validate_isdigit(in_data: dict[str, str], key: str) -> str | bool {
    if in_data[key] == "" {
        return "{} is empty!".format(key);
    } elif in_data[key].isdigit() is False {
        return "{} value is not a numerical string".format(key);
    }
    return True;
}