"""Return a comma separated string of permission changes.

    :param permissions: A list of strings, or ``None``. These strings can
       exclusively contain ``+`` or ``-`` prefixes, or contain no prefixes at
       all. When prefixed, the resulting string will simply be the joining of
       these inputs. When not prefixed, all permissions are considered to be
       additions, and all permissions in the ``known_permissions`` set that
       aren't provided are considered to be removals. When None, the result is
       ``+all``.
    :param known_permissions: A set of strings representing the available
       permissions.

    """
def permissions_string(permissions: list[str] | None, known_permissions: set[str]) -> str {
    to_set = [];
    if permissions is None {
        to_set = ['+all'];
    } else {
        to_set = ['-all'];
        omitted = sorted(known_permissions - set(permissions));
        to_set.extend('-{}'.format(x) for x in omitted);
        to_set.extend('+{}'.format(x) for x in permissions);
    }
    return ','.join(to_set);
}