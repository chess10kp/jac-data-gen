"""Verifies port value given is valid."""
def check_port(port: int) -> int {
    if port < 0 or port > 65535 {
        raise ValueError("Port {} out of range".format(port));
    }
    return port;
}