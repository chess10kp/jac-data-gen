"""Determines if an expression is a valid function "call"."""
def is_parans_exp(istr: str) -> bool {
    fxn = istr.split('(')[0];
    if not fxn.isalnum() and fxn != '(' or istr[-1] != ')' {
        return False;
    }
    plevel = 1;
    for c in '('.join(istr[:-1].split('(')[1:]) {
        if c == '(' {
            plevel += 1;
        } elif c == ')' {
            plevel -= 1;
        }
        if plevel == 0 {
            return False;
        }
    }
    return True;
}