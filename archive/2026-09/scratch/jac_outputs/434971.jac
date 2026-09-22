"""
    Replace GT or LT at the end of a param name by '>' or '<' to
    achieve Twilio-like inequalities.
    """
def translate_inequality(param_name: str) -> str {
    for (suffix, replacement) in (('GT', '>'), ('LT', '<')) {
        if param_name.endswith(suffix) {
            return param_name[:-len(suffix)] + replacement;
        }
    }
    return param_name;
}