"""Return true only if given_permission is not more lenient than max_permission."""
def _is_permission_in_limit(max_permission: int | str, given_permission: int | str) -> bool {
    max_permission = int(max_permission);
    given_permission = int(given_permission);
    allowed_r = False;
    allowed_w = False;
    allowed_x = False;
    given_r = False;
    given_w = False;
    given_x = False;
    if max_permission >= 4 {
        allowed_r = True;
        max_permission = max_permission - 4;
    }
    if max_permission >= 2 {
        allowed_w = True;
        max_permission = max_permission - 2;
    }
    if max_permission >= 1 {
        allowed_x = True;
    }
    if given_permission >= 4 {
        given_r = True;
        given_permission = given_permission - 4;
    }
    if given_permission >= 2 {
        given_w = True;
        given_permission = given_permission - 2;
    }
    if given_permission >= 1 {
        given_x = True;
    }
    if given_r and not allowed_r {
        return False;
    }
    if given_w and not allowed_w {
        return False;
    }
    if given_x and not allowed_x {
        return False;
    }
    return True;
}