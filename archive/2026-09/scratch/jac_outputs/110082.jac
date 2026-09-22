"""Maps given JSON servers array into a server ports list using "port" property."""
def local_ports(servers_list: Any) -> "list[int]" {
    return [game_server["port"] for game_server in servers_list];
}