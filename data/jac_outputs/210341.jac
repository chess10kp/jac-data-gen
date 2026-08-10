"""Heuristically check function or expression."""
def is_jsfunc(func: str) -> bool {
    func = func.strip();
    if func.startswith(('function', 'async ')) {
        return True;
    } elif '=>' in func {
        return True;
    }
    return False;
}