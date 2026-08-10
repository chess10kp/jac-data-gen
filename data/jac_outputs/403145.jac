"""
    returns a variable expression of name NAME
    where NAME is a string
    """
def mk_var_expr(name: str) -> dict[str, str | tuple[str, int]] {
    return {"type": "var", "name": (name, 0)};
}