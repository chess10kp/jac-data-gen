"""
Convert string in format `host:port` to host and port.
"""
def get_host_port(hostport_str: str) -> tuple[str, int] {
    host_port_args = hostport_str.split(":");
    rotctld_host = host_port_args[0];
    rotctld_port = 4533;
    if len(host_port_args) > 1 {
        rotctld_port = int(host_port_args[1]);
    }
    return (rotctld_host, rotctld_port);
}