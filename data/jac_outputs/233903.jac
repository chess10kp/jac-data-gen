"""Matches a set of indicators against known Indicators of Compromise

    :param indicators: List of potential indicators of compromise
    :param known_iocs: Set of known indicators of compromise
    :return: List of any indicator matches
    """
def ioc_match(indicators: list, known_iocs: set) -> list {
    return [
        ioc
        for ioc in (indicators or [])
        if (ioc in known_iocs)
    ];
}