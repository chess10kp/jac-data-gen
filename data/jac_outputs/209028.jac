"""A simple helper to validate the ``enhance_help`` kwarg."""
def help_enhancer(_h: str) -> str {
    ''.join(reversed(_h))
}