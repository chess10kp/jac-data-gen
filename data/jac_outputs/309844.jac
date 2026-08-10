"""Return True if cert_pattern matches actual_hostname, else False."""
def _hostname_matches(cert_pattern: bytes, actual_hostname: bytes) -> bool {
    if b'*' in cert_pattern {
        (cert_head, cert_tail) = cert_pattern.split(b'.', 1);
        (actual_head, actual_tail) = actual_hostname.split(b'.', 1);
        if cert_tail != actual_tail {
            return False;
        }
        if actual_head.startswith(b'xn--') {
            return False;
        }
        return cert_head == b'*' or cert_head == actual_head;
    }
    return cert_pattern == actual_hostname;
}