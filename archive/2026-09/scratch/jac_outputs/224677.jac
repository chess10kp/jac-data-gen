"""Turn instances of links into anchor tags."""
def _LinkifyString(s: str) -> str {
    for component in s.split() {
        if component.startswith('http') {
            component = component.strip(',.!');
            s = s.replace(component, ('<a href="%s">%s</a>' % (component, component)));
        }
    }
    return s;
}