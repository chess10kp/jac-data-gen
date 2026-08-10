"""Creates a new soft link."""
def createSoftLink(src: str, dest: str) -> list[str] {
    return ["ln -f -s %s %s" % (src, dest)];
}