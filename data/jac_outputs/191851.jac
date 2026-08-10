"""
    Used to filter out some special variants that we don't need
    """
def _is_base_font(name: str) -> bool {
    MODIFIERS = ["Display", "Mono", "Slanted"];
    for m in MODIFIERS {
        if name.endswith(m) {
            return False;
        }
    }
    return True;
}