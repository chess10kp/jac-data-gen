"""Return True iff this key refers to a state feature."""
def isStateKey(key: str) -> bool {
    return "'s " in key;
}