"""Return one url if two aren't given else join the two urls."""
def join_urls(first_url: str | None, second_url: str | None) -> str | None {
    if not first_url { return second_url; }
    if not second_url { return first_url; }
    first_url = first_url.strip('/');
    second_url = second_url.lstrip('/');
    return '/'.join([first_url, second_url]);
}