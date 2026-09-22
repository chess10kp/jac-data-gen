obj WebRequest {
    has vars: dict[str, str];
}

"""
    Was an \"edit server\" button pressed?
    """
def is_edit(request: WebRequest, v: str, edit: str = "Edit") -> bool {
    return v.startswith("edit_") and request.vars.get(v) == edit;
}