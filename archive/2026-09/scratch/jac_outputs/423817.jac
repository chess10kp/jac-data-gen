"""Return True if URI has relative protocol '//' """
def has_relative_protocol(uri: str) -> bool {
    return uri[:2] == '//';
}