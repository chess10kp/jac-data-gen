"""Very simple shell-like line splitting."""
def shellsplit(text: str) -> list[str] {
    ret = list();
    inquotes = False;
    current = "";
    for c in text {
        if c == "\"" {
            inquotes = not inquotes;
        } elif c in ("\t", "\n", " ") and not inquotes {
            if current != "" {
                ret.append(current);
            }
            current = "";
        } else {
            current += c;
        }
    }
    if current != "" {
        ret.append(current);
    }
    return ret;
}