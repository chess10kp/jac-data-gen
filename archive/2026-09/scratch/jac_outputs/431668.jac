glob ADMIN_ROLES = [
    'roles/editor',
    'roles/owner',
    'roles/viewer',
    'roles/appengine.appAdmin'
];

"""Get a list of admins from the IAM policy."""
def admins_from_iam_policy(iam_policy: dict[str, list[dict[str, str | list[str]]]]) -> list[str] {
    admins = [];
    for binding in iam_policy['bindings'] {
        if binding['role'] not in ADMIN_ROLES {
            continue;
        }
        for member in binding['members'] {
            (user_type, email) = member.split(':', 2);
            if user_type == 'user' {
                admins.append(email);
            }
        }
    }
    return admins;
}