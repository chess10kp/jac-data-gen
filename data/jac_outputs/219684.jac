"""
Given an urwid (text, attr) tuple (as returned by, e.g.
:meth:`Text.get_text`), returns the first character of the text matching
the *hotkey* attribute, or ``None`` if no character matches.
"""
def find_hotkey(text: str, attrs: list[tuple[str, int]], hotkey: str = 'hotkey') -> str | None {
    ix = 0;
    for (attr, rl) in attrs {
        if attr == hotkey {
            return text[ix];
        }
        ix += rl;
    }
    return None;
}