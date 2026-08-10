"""custom string formatting function for creating a legible label from a parm name
    takes an incoming label, and sets it to title case unless the 'word' is all caps"""
def _prepname(str: Any) -> object {
    parts = ();
    for part in str.split(" ") {
        if not part.isupper() {
            parts += (part.capitalize(), );
        } else {
            parts += (part, );
        }
    }
    return " ".join(parts);
}