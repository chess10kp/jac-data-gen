node Account {
    has role: str = "member";
}

def:priv is_admin() -> bool {
    accts = [root --> [?:Account]];
    return len(accts) > 0 and accts[0].role == "admin";
}

def:priv admin_only_action() -> str {
    if not is_admin() { return "forbidden"; }
    # ... privileged work, e.g. an allroots() scan ...
    return "done";
}
