"""Check the syntax of a `Python` expression."""
def checkSyntax(value: str) -> bool {
    if value[0] in ("'", '"') {
        return False;
    }
    try {
        eval(value);
        return True;
    } except (ValueError, SyntaxError) {
        return False;
    }
}