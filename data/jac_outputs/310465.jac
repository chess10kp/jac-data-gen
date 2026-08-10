"""Return lowercase http method name, if valid. Else, raise Exception."""
def get_http_method_type(method: str) -> str {
    supported_methods = ["get", "post", "put", "delete"];
    m = str(method).lower();
    if m not in supported_methods {
        raise ValueError(
            f"Request method '{method}' not supported. Supported are GET, POST, PUT & DELETE."
        );
    }
    return m;
}