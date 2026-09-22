"""Resolve Quantity and QuantSpec types when combined."""
def resolveSpecTypeCombos(t1: str, t2: str) -> str {
    if t1 == 'RHSfuncSpec' or t2 == 'RHSfuncSpec' {
        return 'RHSfuncSpec';
    } elif t1 == 'ImpFuncSpec' or t2 == 'ImpFuncSpec' {
        return 'ImpFuncSpec';
    }
    return 'ExpFuncSpec';
}