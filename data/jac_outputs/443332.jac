"""Check if arguments are non Null."""
def checkNotNull(params: list[object]) -> bool {
    for value in params {
        if value == None {
            return False;
        }
    }
    return True;
}