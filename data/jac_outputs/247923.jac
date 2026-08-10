import re;

"""Extract definition list items from HTML text."""
def extract_defs(text: str) -> list[str] {
    li_re = re.compile(r'<LI[^>]*>(.*)</LI>');
    html_re = re.compile(r'<[^>]+>\s*');
    return [clean_d for d in li_re.findall(text) if (clean_d := html_re.sub('', d))];
}