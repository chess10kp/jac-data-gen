"""Iterate discovered endpoints."""
def _iterate(discovery_iter: list[tuple[str, str]]) -> list[tuple[str, int]] {
    hostports = [];
    for (_, hostport) in discovery_iter {
        if not hostport {
            continue;
        }
        (host, port) = hostport.split(':');
        hostports.append((host, int(port)));
    }
    return hostports;
}