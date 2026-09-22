"""Check if --ignorePolyA flag was used. If so, change polyA directory to
    no polyA"""
def checkPolyA(ignorePolyA: bool) -> str {
    return 'noPolyA' if ignorePolyA else 'polyA';
}