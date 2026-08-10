"""Normalize the format of a version string."""
def padVersionString(versString: str | int | float | None, tupleCount: int) -> str {
    if versString is None {
        versString = '0';
    }
    components = str(versString).split('.');
    if len(components) > tupleCount {
        components = components[0:tupleCount];
    } else {
        while len(components) < tupleCount {
            components.append('0');
        }
    }
    return '.'.join(components);
}