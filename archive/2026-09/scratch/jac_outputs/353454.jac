"""
Convert the turnc value to a tuple of (True, False) to indicate if it is 5'
or 3' truncated.
"""
def convert_trunc(raw: str | tuple[bool, bool]) -> tuple[bool, bool] {
    if isinstance(raw, tuple) {
        return raw;
    }
    match raw {
        case "no":
            return (False, False);
        case "5'":
            return (True, False);
        case "3'":
            return (False, True);
        case "5'&3'":
            return (True, True);
        case _:
            raise Exception("Unknown yes/no %s" % raw);
    }
}