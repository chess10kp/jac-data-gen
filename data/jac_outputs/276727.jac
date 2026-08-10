"""Return the date histogram interval for the given facet name

    The default is "year".
    """
def date_facet_interval(facet_name: str) -> str {
    parts = facet_name.rpartition('.');
    interval = parts[2];
    if interval in ['month', 'year', 'decade', 'century'] {
        return interval;
    }
    return 'year';
}