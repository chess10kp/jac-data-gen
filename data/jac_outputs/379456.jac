"""Return True if the headers have the required keys."""
def check_headers(headers: dict[str, str]) -> tuple[bool, str] {
    valid_headers = True;
    error_msg = '';
    if not headers {
        error_msg = "Empty headers. Please enter a valid one";
        valid_headers = False;
        return (valid_headers, error_msg);
    }
    if not isinstance(headers, dict) {
        error_msg = "headers should be a dictionnary";
        valid_headers = False;
        return (valid_headers, error_msg);
    }
    if 'content-type' not in headers or 'x-mailerlite-apikey' not in headers {
        error_msg = "headers should be a dictionnary and it contains ";
        error_msg += "'content-type' and 'x-mailerlite-apikey' as keys";
        valid_headers = False;
        return (valid_headers, error_msg);
    }
    return (valid_headers, error_msg);
}