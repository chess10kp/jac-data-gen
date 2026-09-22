"""
    parse a connection string and return a dictionary of values
    """
def connection_string_to_dictionary(str: Any) -> object {
    cn = {};
    for pair in str.split(";") {
        suffix = "";
        if pair.endswith("=") {
            pair = pair.rstrip("=");
            suffix = "=";
        }
        (key, value) = pair.split("=");
        value += suffix;
        cn[key] = value;
    }
    return cn;
}