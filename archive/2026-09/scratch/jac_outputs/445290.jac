"""Tells if `code` is contained in `codelist`."""
def _code_in_list(code: int, codelist: list[str]) -> bool {
    exact_codes = [
        c
        for c in codelist
        if 'x' not in c
    ];
    if str(code) in exact_codes {
        return True;
    }
    class_codes = [
        c[0]
        for c in codelist
        if 'x' in c
    ];
    if str(code)[0] in class_codes {
        return True;
    }
    return False;
}