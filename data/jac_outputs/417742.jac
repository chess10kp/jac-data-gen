"""Make sure no illegal characters are contained in the file name."""
def normpath(pathname: str) -> str {
    import from sys { platform }
    illegal_chars = ":?*";
    for c in illegal_chars {
        if platform == "win32" and c == ":" and pathname[1:2] == ":" {
            pathname = pathname[0:2] + pathname[2:].replace(c, "");
        } else {
            pathname = pathname.replace(c, ".");
        }
    }
    return pathname;
}