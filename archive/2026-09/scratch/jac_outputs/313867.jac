"""Converts a string with the contents 'true' or 'false' to the appropriate boolean value."""
def stringToBool(string: str) -> bool {
    match string {
        case "true":
            return True;
        case "false":
            return False;
        case _:
            raise ValueError("can't convert to boolean: %s" % string);
    }
}