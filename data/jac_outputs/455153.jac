"""Optional WWW-Authenticate header (401 error)"""
def build_authenticate_header(realm: str = '') -> dict[str, str] {
    return {'WWW-Authenticate': 'OAuth realm="%s"' % realm};
}