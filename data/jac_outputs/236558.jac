"""
    Adapted version of policyuniverse's _check_permission_length. We are commenting out the skipping prefix message
    https://github.com/Netflix-Skunkworks/policyuniverse/blob/master/policyuniverse/expander_minimizer.py#L111
    """
def check_min_permission_length(permission: str, minchars: int | str | None = None) -> bool {
    if minchars and len(permission) < int(minchars) and permission != "" {
        return True;
    }
    return False;
}