"""
    utility handler that does nothing more than provide a rejection header
    """
def _error_connection_handler(sock: int, client_addr: str, header: dict[str, str]) -> dict[str, str] {
    return {'error': "unhandled connection"};
}