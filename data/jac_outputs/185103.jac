"""Return standard headers for talking to the metadata service"""
def json_api_headers(token: str) -> dict[str, str] {
    return {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.api+json",
        "Content-Type": "application/vnd.api+json"
    };
}