"""Replace keys by values of repres in rstring."""
def replace_in_str(rstring: str, repres: dict[str, str]) -> str {
    for k in sorted(repres.keys(), key=len, reverse=True) {
        rstring = rstring.replace(k, repres[k]);
    }
    return rstring;
}