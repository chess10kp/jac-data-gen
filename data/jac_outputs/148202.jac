"""
Content-Type: text/html
Set-Cookie: user=gua
    """
def response_with_headers(headers: dict[str, str]) -> str {
    header = 'HTTP/1.1 210 VERY OK\r\n';
    header += ''.join([f'{k}: {v}\r\n' for (k, v) in headers.items()]);
    return header;
}