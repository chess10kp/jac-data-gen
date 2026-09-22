"""Replace special characters '&', '<' and '>' by SGML entities."""
def cgi_escape(s: str, quote: bool = False) -> str {
    if '&' in s {
        s = s.replace("&", "&amp;");
    }
    if '<' in s {
        s = s.replace("<", "&lt;");
    }
    if '>' in s {
        s = s.replace(">", "&gt;");
    }
    if quote {
        s = s.replace('"', "&quot;");
        s = s.replace("'", "&apos;");
    }
    return s;
}