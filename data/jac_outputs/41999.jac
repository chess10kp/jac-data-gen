"""Check if the make variable name seems valid."""
def _is_valid_make_var(varname: str) -> bool {
    if len(varname) == 0 {
        return False;
    }
    invalid_chars = ":#= \t\n\r";
    for char in invalid_chars {
        if char in varname {
            return False;
        }
    }
    return True;
}