"""Returns TRUE iff every element in <phrase> is TRUE"""
def and_sum(phrase: list[bool]) -> bool {
    for x in phrase {
        if not x {
            return False;
        }
    }
    return True;
}