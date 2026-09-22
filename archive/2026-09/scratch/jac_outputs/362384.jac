"""
    checks if function has any semnops that
    can be replaced
    """
def can_semnops(f: object) -> bool {
    return hasattr(f, 'displaced_bytes');
}