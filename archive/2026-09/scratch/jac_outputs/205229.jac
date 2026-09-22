"""
    Determine if a line is a comment line. A valid line contains at least three
    words, with the first two being integers. Note that Python 2 and 3 deal
    with strings differently.
    """
def _iscomment(line: Any) -> object {
    if line.isspace() {
        return True;
    } elif (len(line.split()) >= 3) {
        try {
            if (line.split()[0].isdecimal() and line.split()[1].isdecimal()) {
                return False;
            }
        } except Exception as e {
            if (
                line.decode().split()[0].isdecimal()
                and line.split()[1].decode().isdecimal()
            ) {
                return False;
            }
        }
        return True;
    } else {
        return True;
    }
}