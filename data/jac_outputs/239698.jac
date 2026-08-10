"""
    fill ip, port and message for the connection.
    """
def _fill_common_details(host: Any, port: Any, message: Any) -> object {
    cert_details = {};
    cert_details['ssl_src_port'] = str(port);
    cert_details['error'] = message;
    cert_details['ssl_src_host'] = str(host);
    return cert_details;
}