"""Return true if this seems continued line."""
def ContinuedLine(level3: str, towns: list[str]) -> bool {
    for town in towns {
        if level3.startswith(town) {
            return False;
        }
    }
    return True;
}