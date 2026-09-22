"""Append = or == to the b64 string."""
def pad_b64(encoded: str) -> str {
    remainder = len(encoded) % 4;
    if remainder == 3 {
        encoded += "=";
    } elif remainder == 2 {
        encoded += "==";
    }
    return encoded;
}