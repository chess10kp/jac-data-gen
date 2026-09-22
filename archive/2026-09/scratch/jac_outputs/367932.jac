import re;

"""Convert a post to safe HTML, quote any HTML code, convert
    URLs to live links and spot any @mentions or #tags and turn
    them into links.  Return the HTML string"""
def post_to_html(content: str) -> str {
    content = content.replace("&", "&amp;");
    content = content.replace("<", "&lt;");
    content = content.replace(">", "&gt;");
    r = re.compile(r"(http://[^ ]+)");
    return r.sub(r'<a href="\1">\1</a>', content);
}