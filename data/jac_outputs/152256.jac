"""
        extractPortFromName takes a string in the form `id:port` and returns the ID and the port
        If there's no `:`, the default port is returned
        """
def extract_port_from_name(name: str, default_port: int | str) -> tuple[str, str | int] {
    idx = name.rfind(":");
    if idx >= 0 {
        return (name[:idx], name[idx + 1:]);
    }
    return (name, default_port);
}