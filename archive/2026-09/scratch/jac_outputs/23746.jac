"""Get the position of the end of the aspect/opinion span in a tagging sequence."""
def find_tail(tags: list[int], num: int) -> int {
    last = False;
    for (i, x) in enumerate(tags) {
        if x != num and last {
            return i - 1;
        }
        if x == num + 1 {
            last = True;
        }
    }
    return len(tags) - 1 if last else -1;
}