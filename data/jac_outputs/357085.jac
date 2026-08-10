"""Return the token given an input of 'Bearer <token>'."""
def __parseAuthHeader(string: str) -> str {
    components = string.split(' ');
    if len(components) != 2 {
        raise ValueError('Invalid authorization header.');
    }
    return components[1];
}