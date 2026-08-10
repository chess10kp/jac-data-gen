"""Replace a set of multiple sub strings with a new string."""
def replaceMultiple(mainString: str, toBeReplaces: list[str] | set[str], newString: str) -> str {
    for elem in toBeReplaces {
        if elem in mainString {
            mainString = mainString.replace(elem, newString);
        }
    }
    return mainString;
}