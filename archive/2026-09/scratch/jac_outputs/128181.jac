"""Check syntax of the UUID, utility function."""
def checkuuidsyntax(uuidtxt: str | None) -> int {
    score = 0;
    if uuidtxt != None {
        if len(uuidtxt) < 10 {
            score = 0;
        } elif uuidtxt.find("{") > -1 or uuidtxt.find("}") > -1 or uuidtxt.lower() != uuidtxt {
            score = 1;
        } else {
            score = 2;
        }
    }
    return score;
}