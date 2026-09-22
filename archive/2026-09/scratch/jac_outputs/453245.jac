"""
Helper to build urls, with slightly different behavior from
urllib.parse.urljoin.
"""
def join_url(*sections: str) -> str {
    return '/'.join(s.strip('/') for s in sections);
}