"""
Converts a (real, logical) pair into one of the three types:
'real', 'complex' and 'binary'
"""
def getdtype(real: bool, logical: bool) -> str {
    return "binary" if logical else "real" if real else "complex";
}