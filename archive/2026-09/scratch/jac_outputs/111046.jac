"""Generate curl command for token API authentication."""
def _generate_token_cmd(path: str, username: str, password: str) -> str {
    body = '{"username": "%s", "password": "%s"}' % (username, password);
    return "curl -X POST -H 'Content-Type: application/json' -d '%s' %s" % (body, path);
}