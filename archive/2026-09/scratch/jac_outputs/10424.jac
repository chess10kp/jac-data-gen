"""Normalize email addresses to the internal blacklist/whitelist format."""
def normalizeAddress(address: str) -> str {
    if address.startswith("<") {
        return address;
    }
    return "<" + address + ">";
}