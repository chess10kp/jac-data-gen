"""Return True if a string represents a valid range definition and False otherwise."""
def _is_range_format_valid(format_string: str) -> bool {
    if "~" in format_string {
        if len(format_string.split("~")) != 2 {
            return False;
        }
        format_string = format_string.replace("~", "");
        return format_string.isalnum() or format_string == "";
    }
    return format_string.isalnum();
}