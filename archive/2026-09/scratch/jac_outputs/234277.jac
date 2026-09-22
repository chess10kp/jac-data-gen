"""Returns an item of a list_, or false if this element doesn't exist."""
def li[T](list_: list[T], c: int) -> T | bool {
    if len(list_) > c {
        return list_[c];
    }
    return False;
}