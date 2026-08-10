"""entity [A|B]----B"""
def parse(h: str) -> str {
    if "[" in h and "|" in h and "]" in h {
        return h.split("|")[1].split("]")[0];
    }
    return h;
}