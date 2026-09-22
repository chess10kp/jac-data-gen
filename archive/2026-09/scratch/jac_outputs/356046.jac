"""
    Returns the fields for `UserDetailSerializer`.
    """
def get_userdetail_fields(fields: list[str] | tuple[str, ...]) -> tuple[str, ...] {
    fields = list(fields);
    fields.remove('is_superuser');
    fields.remove('user_permissions');
    return tuple(fields);
}