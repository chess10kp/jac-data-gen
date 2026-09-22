"""
    Parses a typical steem URL and returns a tuple
    including the author and permlink.
    Ex: http://steemit.com/@author/permlink
    """
def parse_author_and_permlink(url: Any) -> object {
    try {
        author = url.split("@")[1].split("/")[0];
        permlink = url.split("@")[1].split("/")[1];
    } except IndexError as e {
        raise ValueError("This is not valid Steem permlink.");
    }
    return (author, permlink);
}