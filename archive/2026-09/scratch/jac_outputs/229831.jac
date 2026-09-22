"""Given a network URL, return the name of the network."""
def get_network_name_from_url(network_url: str) -> str {
    return network_url.split('/')[-1];
}