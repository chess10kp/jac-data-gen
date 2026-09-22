"""Value must be an HTML color string"""
def validate_hcl(value: str) -> bool {
    if (not value.startswith("#") or (len(value) != 7)) {
        return False;
    }
    try {
        int(value[1:], 16);
    } except ValueError {
        return False;
    } else {
        return True;
    }
}