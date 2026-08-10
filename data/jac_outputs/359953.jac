"""Returns True if a given IP string is v6, False otherwise."""
def is_v6(ip_string: str) -> bool {
    return (":" in ip_string);
}