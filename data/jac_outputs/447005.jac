"""Mock _get_response() function."""
def mock_get_response(url: Any) -> object {
    json_data = False;
    if url.lower().startswith('https') {
        json_data = {'titles': ['title is found']};
    }
    return json_data;
}