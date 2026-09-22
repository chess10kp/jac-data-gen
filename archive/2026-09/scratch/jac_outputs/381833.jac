"""Build network URI for NSX Proxy API."""
glob NETWORK_URL = '/network/edges/';
glob GATEWAY_API_URL = '/api/edgeGateway/';
glob GATEWAY_ADMIN_API_URL = '/api/admin/edgeGateway/';

def build_network_url_from_gateway_url(gateway_href: str) -> str | None {
    network_url = gateway_href;
    if gateway_href.find(GATEWAY_API_URL) > 0 or gateway_href.find(GATEWAY_ADMIN_API_URL) > 0 {
        network_url = network_url.replace(GATEWAY_API_URL, NETWORK_URL);
        return network_url.replace(GATEWAY_ADMIN_API_URL, NETWORK_URL);
    }
    return None;
}