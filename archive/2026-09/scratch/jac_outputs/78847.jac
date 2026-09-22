"""Check whether parsed_param contains any valid param value listed in valid_values.
if yes, return the valid param value appearing in parsed_param;
if no, return False"""
def check_param_validation(parsed_param: str, valid_values: list[str]) -> str | bool {
    if not valid_values {
        return parsed_param;
    }
    for value in valid_values {
        if value in parsed_param {
            return value;
        }
    }
    return False;
}