"""Return a tuple containing (host, port) of a string possibly
    containing both.  If there is no port in host_port, the port
    will be None.

    Supports the following:
    - hostnames
    - ipv4 addresses
    - ipv6 addresses
    with or without ports.  There is no validation of either the
    host or port.

    """
def split_host_port(host_port: str) -> tuple[str, str | None] | list[str] {
    colon_count = host_port.count(':');
    match colon_count {
        case 0:
            return (host_port, None);
        case 1:
            return host_port.split(':', 1);
        case _ if colon_count >= 2:
            if ']:' in host_port {
                parts = host_port.split(']:', 1);
                host = parts[0] as str;
                port = parts[1] as str;
                if host[0] == '[' {
                    host = host[1:];
                }
                return (host, port);
            }
            host = host_port as str;
            if host[0] == '[' {
                host = host[1:];
            }
            if host[-1] == ']' {
                host = host[:-1];
            }
            return (host, None);
    }
}