"""Get the size of a data descriptor tuple."""
def getsize(datadescriptor: tuple[str, tuple[int, ...]]) -> tuple[int, int | str] {
    if datadescriptor[0] == 'reg' {
        size = datadescriptor[1][2];
    } elif datadescriptor[0] == 'mem' {
        size = datadescriptor[1][1];
    } elif datadescriptor[0] == 'heap' {
        size = datadescriptor[1][2];
    } elif datadescriptor[0] == 'perp' {
        size = datadescriptor[1][2];
    } elif datadescriptor[0] == 'pmem' {
        size = datadescriptor[1][2];
    } else {
        return (15, "Not a supported destination type.");
    }
    return (0, size);
}