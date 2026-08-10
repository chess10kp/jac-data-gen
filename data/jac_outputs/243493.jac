"""
Verifies that a specified field is not present in a raw data structure.

Returns True if the field was not present, False if it was.
"""
def check_not_present(context: str, raw_data: dict, raw_field: str) -> bool {
    if raw_field not in raw_data {
        return True;
    }
    print(f"field value {raw_field} should be absent from {context}, but is not");
    return False;
}