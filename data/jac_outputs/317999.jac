"""Auxillary funtion."""
def get_ckpt_name(scope: str | None) -> str {
    if scope is None {
        return 'all_scopes.ckpt';
    }
    return '{}_scope.ckpt'.format(scope);
}