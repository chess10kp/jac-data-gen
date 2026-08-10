"""Convert bytes or text to a c-style escaped string."""
def strescape(txt: str | bytes) -> str {
    if isinstance(txt, bytes) {
        txt = txt.decode("cp1251");
    }
    txt = txt.replace("\\", "\\\\");
    txt = txt.replace("\n", "\\n");
    txt = txt.replace("\r", "\\r");
    txt = txt.replace("\t", "\\t");
    txt = txt.replace('"', '\\"');
    return txt;
}