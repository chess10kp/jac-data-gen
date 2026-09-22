"""Get a fake log msg when a farmer receives data from a harvester."""
def msg_from_harvester(timestamp_str: str, ip_address: str, node_id: str) -> str {
    line = f"{timestamp_str} farmer farmer_server              : DEBUG"
        + f"    <- farming_info from peer {node_id} {ip_address}";
    return line;
}