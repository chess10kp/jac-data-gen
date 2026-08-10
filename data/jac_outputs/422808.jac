"""Check if a desired scope wants is part of an available scope has."""
def check(wants: int, `has: int) -> bool {
    if (wants & `has) == 0 {
        return False;
    }
    if (wants & `has) < wants {
        return False;
    }
    return True;
}