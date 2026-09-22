"""
    Validate NetBox custom field environment variable
    """
def validate_nb_custom_field(custom_field: Any) -> object {
    if ((custom_field == "") or (custom_field is None)) {
        print("Missing custom_field to update");
        return False;
    }
    return True;
}