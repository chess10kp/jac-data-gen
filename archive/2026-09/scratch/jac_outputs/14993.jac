"""Builds an error message to add to the queue."""
def build_error_msg(error: str, code: int = 10) -> dict[str, str | dict[str, int | str]] {
    return {
        'jsonrpc': '2.0',
        'error': {'code': code, 'message': f'{error}'},
        'id': 'app_error'
    };
}