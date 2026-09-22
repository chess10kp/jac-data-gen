"""Return str representation of byte object"""
def byte2str(e: bytes) -> str {
    return e.decode("utf-8");
}