"""Hack to make sphinxcontrib.ansi recognized sequences"""
def default_colors_to_resets(s: bytes) -> bytes {
    return s.replace(b'[39m', b'[0m').replace(b'[49m', b'[0m');
}