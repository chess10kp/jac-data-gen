"""Encode booleans to produce valid XML"""
def encode_bool(value: bool) -> str {
    if value {
        return "true";
    }
    return "false";
}