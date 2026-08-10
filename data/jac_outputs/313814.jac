"""Returns a dictionary of headers with authorization token."""
def init_headers(token: str) -> dict[str, str] {
  headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token
  };
  return headers;
}