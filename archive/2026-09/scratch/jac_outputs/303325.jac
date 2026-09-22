"""
Determine whether the given ID is a bundle ID or a
a path to a command
"""
def _client_type(app_id: str) -> str {
    return "1" if app_id[0] == "/" else "0";
}