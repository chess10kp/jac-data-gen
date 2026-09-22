"""
    get the true URL of an otherwise messy URL
    """
def get_true_url(url: str) -> str {
    data = url.split("/");
    "{}//{}".format(data[0], data[2])
}