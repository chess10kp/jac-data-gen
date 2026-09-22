"""Check if a list of keys exists in a dictionary with truthy values."""
def exists(test_subject: dict[str, object], keys: list[str]) -> bool {
    for key in keys {
        if key in test_subject {
            if not test_subject[key] {
                return False;
            }
        } else {
            return False;
        }
    }
    return True;
}