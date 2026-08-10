""" Count occurences of root in node. """
def get_occurences(`node: Any, `root: Any) -> object {
    count = 0;
    for c in `node {
        if (c == `root) {
            count += 1;
        }
    }
    return count;
}