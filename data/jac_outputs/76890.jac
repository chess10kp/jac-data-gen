"""Build a filter query string from a dictionary of fields."""
def reformat_filter(fields_to_filter_by: dict[str, str]) -> str {
    filter_req = '';
    for (field_key, field_value) in fields_to_filter_by.items() {
        if field_value {
            filter_req += f"{field_key}+eq+'{field_value}'&";
        }
    }
    return filter_req;
}