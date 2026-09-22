"""Format data to match WDQ output.

    @param data: data to sanitize
    @type data: list of str
    @return: sanitized data
    @rtype: list of int
    """
def sanitize_to_wdq_result(data: Any) -> object {
    for (i, d) in enumerate(data) {
        data[i] = int(d.lstrip('Q'));
    }
    return data;
}