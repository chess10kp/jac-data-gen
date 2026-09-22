"""
    get similar between a string and a string in  a list
    """
def similarL1(a: str, b: list[str]) -> bool {
    any(x.lower() in a.lower() for x in b)
}