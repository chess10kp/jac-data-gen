"""Non-strict implication"""
def non_strict_impl(a: bool | None, b: bool | None) -> bool | None {
    if a == False {
        return True;
    } elif a == True {
        return b;
    } elif b == True {
        return True;
    } else {
        return None;
    }
}