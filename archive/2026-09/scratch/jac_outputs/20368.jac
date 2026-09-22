"""
Interpret a string as a boolean.

Any string value in:
    ('True', 'true', 'On', 'on', '1')
is interpreted as a boolean True.

Useful for JSON-decoded stuff and config file parsing
"""
def bool_from_string(subject: bool | str) -> bool {
    if type(subject) == type(bool) {
        return subject as bool;
    }
    if hasattr(subject, 'startswith') {
        if (subject as str).strip().lower() in ('true', 'on', '1') {
            return True;
        }
    }
    return False;
}