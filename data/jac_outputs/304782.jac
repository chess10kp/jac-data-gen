"""Basic html escaping."""
def _escape(txt: str) -> str {
    txt = txt.replace('&', '&amp;');
    txt = txt.replace('<', '&lt;');
    txt = txt.replace('>', '&gt;');
    txt = txt.replace('"', '&quot;');
    return txt;
}