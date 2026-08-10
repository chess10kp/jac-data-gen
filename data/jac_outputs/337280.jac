"""Escape &, <, >, ", ', etc. in a string of data."""
def _xml_escape(data: Any) -> object {
    from_symbols = "&><\"'";
    to_symbols = (("&" + s + ";") for s in "amp gt lt quot apos".split());
    for (from_, to_) in zip(from_symbols, to_symbols) {
        data = data.replace(from_, to_);
    }
    return data;
}