"""Returns True if the text is likely a normal wind element"""
def is_wind(text: str) -> bool {
    if text.startswith("WS") {
        return False;
    }
    if (len(text) > 4) {
        for ending in ("KT", "KTS", "MPS", "KMH") {
            if text.endswith(ending) {
                return True;
            }
        }
    }
    if not (
        (len(text) == 5)
        or (((len(text) >= 8) and (text.find("G") != -1)) and (text.find("/") == -1))
    ) {
        return False;
    }
    return (text[:5].isdigit() or (text.startswith("VRB") and text[3:5].isdigit()));
}