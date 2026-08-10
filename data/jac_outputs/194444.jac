"""
    Gets the root of a url

    Inputs:
    link - the url of the page

    Output:
    Returns the root of the link if it can fint it. Otherwise, returns -1.
    """
def get_link_root(link: str) -> str {
    websites = ["com", "org", "net", "int", "edu", "gov", "mil"];
    for extension in websites {
        index = link.find(extension);
        if index != -1 {
            return link[0:index + 3] + "/";
        }
    }
    return "-1";
}