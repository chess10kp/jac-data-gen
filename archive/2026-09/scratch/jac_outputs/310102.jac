"""Check if value is a number by casting to float."""
def is_number(my_value: str | int | float) -> bool {
    try {
        float(my_value);
        return True;
    } except Exception {
        return False;
    }
}