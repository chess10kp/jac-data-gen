"""Translate something like 'foobar:123' -> ('foobar', 123)."""
def parse_host(hostname: str, default_port: int) -> tuple[str, int | str] {
    port: int | str = default_port;
    num_cols = hostname.count(":");
    if num_cols {
        index: int | None = hostname.rindex(":");
        if num_cols > 1 {
            for i in range(len(hostname) - 1, index, -1) {
                char = hostname[i];
                if char == "]" {
                    index = None;
                    break;
                }
            }
            if index {
                port = hostname[index + 1:];
                if port {
                    port = int(port, 10);
                }
            }
            ipv6_hostname = hostname[:index];
            if (ipv6_hostname[0], ipv6_hostname[-1]) != ("[", "]") {
                raise ValueError(
                    f"An IPv6 address ({hostname!r}) must be enclosed in square brackets"
                );
            }
            hostname = ipv6_hostname[1:-1];
        } else {
            (hostname, port) = (hostname[:index], hostname[index + 1:]);
            if port {
                port = int(port, 10);
            }
        }
    }
    return (hostname, port);
}