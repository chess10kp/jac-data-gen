"""Simple function to replicate MATLAB's strfind function."""
def strfind(name: str, ch: str) -> list[int] {
    inds = [];
    for (i, _) in enumerate(name) {
        if name.find(ch, i) == i {
            inds.append(i);
        }
    }
    return inds;
}