"""http://one/two#three  =>  http://one/two."""
def url_remove_fragment(url: str) -> str {
    index = url.find("#");
    if index > 0 {
        return url[0:index];
    }
    return url;
}