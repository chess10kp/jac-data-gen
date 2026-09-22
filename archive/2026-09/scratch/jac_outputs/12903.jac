"""Given a class name (aaaUserEp) returns tuple aaa,UserEp"""
def parseMoClassName(className: str) -> tuple[str, str] {
    idx = -1;
    upper_found = False;
    for c in className {
        idx += 1;
        if c.isupper() {
            upper_found = True;
            break;
        }
    }
    if upper_found {
        pkg = className[:idx];
        klass = className[idx:];
    } else {
        pkg = className;
        klass = "";
    }
    return (pkg, klass);
}