"""Utility method that checks to see if variable_type is a float"""
def is_scale_type(variable_type: str | int | float | bool) -> bool {
    try {
        float(variable_type);
        return True;
    } except ValueError {
        return False;
    }
}