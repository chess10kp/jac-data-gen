""" This function returns number of lines from the poem string. """
def lineCount(poemString: Any) -> object {
    lines = poemString.splitlines();
    if ("" in lines) {
        lines.remove("");
    }
    return len(lines);
}