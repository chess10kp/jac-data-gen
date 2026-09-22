"""Quote attributes for pseudo-xml"""
def pseudo_quoteattr(value: str) -> str {
    return '"%s"' % value;
}