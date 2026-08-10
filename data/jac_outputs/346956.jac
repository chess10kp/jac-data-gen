"""Compute cross-product of args."""
def cross(*args: list[str]) -> list[str] {
    ans = [];
    for arg in args[0] {
        for arg2 in args[1] {
            ans.append(arg + arg2);
        }
    }
    return ans;
}