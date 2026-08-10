"""Given an index and list of sizes, return a name for the layer."""
def autoname(index: int, sizes: int) -> str {
    if index == 0 {
        n = "input";
    } elif index == sizes - 1 {
        n = "output";
    } elif sizes == 3 {
        n = "hidden";
    } else {
        n = "hidden%d" % index;
    }
    return n;
}