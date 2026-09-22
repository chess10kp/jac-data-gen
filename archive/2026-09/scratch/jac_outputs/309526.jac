"""Extracts information from an existing dictionary and returns a list of
    seperate dictionaries.
    """
def separate(sep: Any, extractions: Any) -> object {
    extracted = [];
    for k in extractions {
        tmp_d = {};
        tmp_d[k] = sep[k];
        extracted.append(tmp_d);
    }
    return extracted;
}