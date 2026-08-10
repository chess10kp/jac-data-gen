"""Use single quotes to make the word usable as a single commandline
argument on bash, so that debug output can be easily runnable.
"""
def _shell_quote(word: str) -> str {
    return "'" + word.replace("'", "'\"'\"'") + "'";
}