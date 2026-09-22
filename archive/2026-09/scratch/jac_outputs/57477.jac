"""
Returns <a href="s">addee</a>
For example, <a href="page_url">page_label</a>
"""
def add_link_(s: str, addee: str) -> str | None {
    if s.startswith('http') {
        a = '<a href="{0}" target="_blank">'.format(s);
        a += addee;
        a += '</a>';
        return a;
    }
}