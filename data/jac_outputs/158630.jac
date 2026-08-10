"""
Create an appropriate collector URL given the parameters.

`secure` should be a bool.
"""
def _collector_url_from_hostport(
    secure: bool,
    host: str,
    port: int,
    use_thrift: bool
) -> str {
    protocol = 'https://' if secure else 'http://';
    if use_thrift {
        return ''.join([protocol, host, ':', str(port), '/_rpc/v1/reports/binary']);
    }
    return ''.join([protocol, host, ':', str(port), '/api/v2/reports']);
}