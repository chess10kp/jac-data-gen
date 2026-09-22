"""Convert a variable name (such as "t5") to an integer (in this case 5)."""
def var_to_int(var: str) -> int {
    int(var[1:])
}