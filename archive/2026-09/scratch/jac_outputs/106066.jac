"""Auxiliary function to extract org information from affiliation
    for authorgroup.
    """
def _get_org(aff: dict[str, str | dict[str, str] | list[dict[str, str] | None]]) -> str | None {
    org: str | None = None;
    try {
        tmp = aff['organization'];
        if not isinstance(tmp, str) {
            try {
                tmp = tmp['$'];
            } except TypeError {
                tmp = ', '.join([d['$'] for d in tmp if d]);
            }
        }
        org = tmp;
    } except KeyError {
        org = None;
    }
    return org;
}