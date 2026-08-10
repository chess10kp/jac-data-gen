"""
    Takes report and checks for needed fields
    :param report: list
    :rtype: bool
    """
def _is_noop_report(`report: Any) -> object {
    try {
        return ('noop' in `report['summary']['events']);
    } except (KeyError, AttributeError, TypeError) {
        return False;
    }
}