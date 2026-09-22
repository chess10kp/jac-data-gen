"""Creates the URL of the user's fork."""
def fork_url(feedstock_url: str, username: str) -> str {
    (beg, end) = feedstock_url.rsplit("/", 1);
    beg = beg[:-11];
    return beg + username + "/" + end;
}