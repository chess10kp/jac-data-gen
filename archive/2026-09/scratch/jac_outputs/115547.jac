"""
    Given a timezone string, convert it to a two-tuple suitable
    for a choice in a FormField.

    >>> timezone_choice('UTC')
    ('UTC', 'UTC')
    >>> timezone_choice('Australia/Sydney')
    ('Australia/Sydney', 'Sydney')
    >>> timezone_choice('America/Indiana/Indianapolis')
    ('America/Indiana/Indianapolis', 'Indianapolis (Indiana)')
    """
def timezone_choice(tzname: str, country: str | None = None) -> tuple[str, str] {
    try {
        (base, rest) = tzname.split('/', 1);
    } except ValueError {
        (base, rest) = (None, tzname);
    }
    rest = rest.replace('_', ' ');
    try {
        (mid, rest) = rest.split('/');
        if mid != base and mid != country {
            rest = '{0} ({1})'.format(rest, mid);
        }
    } except ValueError {
        ;
    }
    return (tzname, rest);
}