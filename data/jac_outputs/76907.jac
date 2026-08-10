glob PUNCTUATION = (",", ".", "!", "?");

"""Remove or add spaces around the punctuation signs."""
def format_punctuation(txt: str) -> str {
    for i in range(len(txt) - 1) {
        if txt[i] in PUNCTUATION {
            if txt[i - 1] == " " {
                txt = txt[:i - 1] + txt[i:];
                return format_punctuation(txt);
            }
            if txt[i + 1] != " " and txt[i + 1] != "\n" {
                txt = txt[:i + 1] + " " + txt[i + 1:];
                return format_punctuation(txt);
            }
        }
    }
    return txt;
}