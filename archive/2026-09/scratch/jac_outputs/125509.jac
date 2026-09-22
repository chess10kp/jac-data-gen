"""For Cylinder.001 returns int 1."""
def getNameIndex(name: str) -> int {
    try {
        location = len(name) - "".join(reversed(name)).index(".");
        index = int(name[location:]);
    } except Exception {
        index = 0;
    }
    return index;
}