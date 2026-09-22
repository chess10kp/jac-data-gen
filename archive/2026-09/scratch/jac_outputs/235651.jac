"""
A function to get LASTTOKEN from the url header.
"""
def getKeys(header: dict[str, str]) -> dict[str, str] {
    cookie = {};
    key_sections = header['Set-Cookie'].split(", ");
    for x in key_sections {
        cookie[x.split('=')[0]] = x.split('=')[1];
    }
    return cookie;
}