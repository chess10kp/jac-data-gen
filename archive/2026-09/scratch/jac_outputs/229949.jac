"""Are these four-digit numbers cyclic?"""
def is_cyclic(x: Any, y: Any) -> object {
    return (str(int(x))[2:] == str(int(y))[:2]);
}