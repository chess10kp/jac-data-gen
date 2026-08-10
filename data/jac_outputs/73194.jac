"""
Content-Type: text/html
Set-Cookie: user=gua
"""
def response_with_headers(headers: dict[str, str]) -> str {
    header = 'HTTP/1.x 210 VERY OK\r\n';
    header += ''.join(['{}: {}\r\n'.format(k, v) for (k, v) in headers.items()]);
    return header;
}