"""Return true if the argument starts with a dash ('-') and is not a number"""
def istag(arg: str) -> bool {
    return arg.startswith('-') and len(arg) > 1 and arg[1] not in '0123456789';
}