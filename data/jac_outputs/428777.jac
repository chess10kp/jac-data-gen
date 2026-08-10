"""
Encodes some things as HTML Entities, making them safe to print anywhere.

Currently changes [&<>'"] "'# work around Emacs bug...
"""
def encodeHTML(string: str) -> str {
    string.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;').replace("'", '&apos;')
}