"""Return list of params as params."""
def parametrize(params: list[object]) -> str {
    returned = str(params[0]);
    returned += "".join(["[" + str(p) + "]" for p in params[1:]]);
    return returned;
}