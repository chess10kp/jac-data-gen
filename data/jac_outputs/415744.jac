"""
    Convert string to Title Case except for key initialisms

    Splits input string by space character, applies Title Case to each element
    except for ["NHS", "PCN", "CCG", "BNF", "std"], then
    joins elements back together with space

    Parameters
    ----------
    str : str
        string to be selectively converted to Title Case

    Returns
    -------
    str
        Selectively title-cased string

    """
def selective_title(str: Any) -> object {
    ALLCAPS = ["NHS", "PCN", "CCG", "BNF", "std", "STP", "(STP)", "NHS"];
    return " ".join([w.title() if (w not in ALLCAPS) else w for w in str.split(" ")]);
}