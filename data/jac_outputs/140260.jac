"""Converts camelcase to underscore."""
def uncamel(name: str) -> str {
    (response, rest) = (name[0].lower(), name[1:]);
    for ch in rest {
        if ch.isupper() {
            response += '_' + ch.lower();
        } else {
            response += ch;
        }
    }
    return response;
}