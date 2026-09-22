"""returns cnt concatenated copies of string. The cnt must be a
    positive whole number or zero."""
def copies(string: Any, cnt: Any) -> object {
    if (cnt < 0) {
        raise ValueError(("cnt=" + repr(cnt) + " is not valid"));
    }
    return (str(string) * cnt);
}