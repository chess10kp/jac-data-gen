"""Wrap the data with the resource wrapper used by CAI."""
def resource_wrapper(data: dict) -> dict[str, str | dict | None] {
    return {
        'version': 'v1',
        'discovery_document_uri': None,
        'discovery_name': None,
        'resource_url': None,
        'parent': None,
        'data': data
    };
}