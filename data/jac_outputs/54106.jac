"""
Translates string representing boolean value into boolean value
"""
def str_to_bool(s: str) -> bool {
    match s {
        case "True":
            return True;
        case "False":
            return False;
        case _:
            raise ValueError;
    }
}