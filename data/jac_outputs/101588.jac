"""(<abc>12345</def>, <abc>, </def>)  ->  12345"""
def str_between(string: str, start: str, end: str | None = None) -> str {
    content = string.split(start, 1)[-1];
    if end is not None {
        content = content.rsplit(end, 1)[0];
    }
    return content;
}