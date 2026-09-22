"""Allows you to replace everything you need in one function using two lists."""
def hyper_replace(text: str | int | float | bool, old: list[str], new: list[str]) -> str {
    msg = str(text);
    for (x, y) in zip(old, new) {
        msg = str(msg).replace(x, y);
    }
    return msg;
}