"""Replace ``*`` with ``\*`` so that is will be parsed properly by
    docutils.

    """
def fix_star(word: str) -> str {
    word.replace('*', '\\*')
}