"""Delete query arguments from the link."""
def cut_arguments(url: str) -> str {
    mark = url.find('?');
    if mark != -1 {
        url = url[:mark];
    }
    return url;
}