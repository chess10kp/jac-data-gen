"""
    Parses/interprets the provided cookie data string, returning a
    map structure containing key to value associations of the various
    parts of the cookie.

    In case no key value association exists for the cookie the value
    for such cookie (key) is stored and an empty string (unset).

    :type data: String
    :param data: The cookie serialized data that is going to be parsed
    in order to create the final cookie dictionary/map.
    :rtype: Dictionary
    :return: The final map containing key the value association for the
    various parts of the provided cookie string.
    """
def parse_cookie(data: str) -> dict[str, str] {
    cookie_m = dict();
    cookies = [cookie.strip() for cookie in data.split(";")];
    for cookie in cookies {
        if not "=" in cookie {
            cookie += "=";
        }
        (name, value) = cookie.split("=", 1);
        cookie_m[name] = value;
    }
    return cookie_m;
}