"""Split the string by the version:
    mypacakge<=2.4,==2.4 -> (mypacakge, <=2.4,==2.4)

    In [40]: version_split("asdsda>=2.4,==2")
    Out[40]: ('asdsda', ['>=2.4', '==2'])

    In [41]: version_split("asdsda>=2.4")
    Out[41]: ('asdsda', ['>=2.4'])

    In [42]: version_split("asdsda")
    Out[42]: ('asdsda', [])
    """
def version_split(s: str, delimiters: set[str] = {"=", ">", "<", "~"}) -> tuple[str, list[str]] {
    for (i, c) in enumerate(s) {
        if c in delimiters {
            return (s[:i], s[i:].split(","));
        }
    }
    return (s, []);
}