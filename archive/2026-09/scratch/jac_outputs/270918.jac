"""Combine *node* and *terminal* to a key into the results set for the current template.

Returns a string unique within the template that can be used in JSON.
"""
def _key(`node: str | int, terminal: str | int) -> str {
    return ":".join((str(`node), str(terminal)));
}