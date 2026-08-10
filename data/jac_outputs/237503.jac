"""
## Example
`isSubKey("Rocket", "Rocket.name")` -> True
`isSubKey("SimControl", "Rocket.name")` -> False
"""
def isSubKey(potentialParent: str, potentialChild: str) -> bool {
    if potentialParent == "" {
        return True;
    }
    parent_len = len(potentialParent);
    if len(potentialChild) <= parent_len {
        return False;
    }
    return potentialChild[:parent_len] == potentialParent
        and potentialChild[parent_len] == ".";
}