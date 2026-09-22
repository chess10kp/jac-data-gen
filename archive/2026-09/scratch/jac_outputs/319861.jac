"""Determine whether subState is a substate of parentState."""
def isSubstateOf(parentState: str | None, subState: str | None) -> bool {
    if parentState is None or subState is None {
        return False;
    }
    if parentState == subState {
        return True;
    }
    if len(subState) <= len(parentState) {
        return False;
    }
    if subState[:len(parentState) + 2] == parentState + '__' {
        return True;
    }
    return False;
}