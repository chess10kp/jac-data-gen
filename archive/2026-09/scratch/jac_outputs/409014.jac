"""remove unexpected characters"""
def _clean_page_wheel(text: str) -> str {
    text = text.replace("&quot;", "'");
    text = text.replace("&#8209;", "-");
    text = text.replace("&#46;", ".");
    text = text.replace(" &middot; ", "-");
    text = text.replace("&ndash;", "-");
    return text;
}