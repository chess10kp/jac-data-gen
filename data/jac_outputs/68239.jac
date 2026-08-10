"""Used to verify that <input> type textboxes that should be integers actually are."""
def verify_integer(filter_value: str | int | float) -> bool {
    try {
        int(filter_value);
        return True;
    } except Exception {
        return False;
    }
}