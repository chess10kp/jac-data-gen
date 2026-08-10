"""Inserts zero-width-space HTML entities after each underscore IF the keyword is long.
       This is useful to allow long keywords to be split into different lines.
    """
def make_breakable(keyword: str) -> str {
    '_&ZeroWidthSpace;'.join(keyword.split('_')) if len(keyword) > 30 else keyword
}