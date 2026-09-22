def locate_registry(locate: str) -> str | list[str] {
    paths = locate.split('.');
    for k in paths {
        if k in ('factory', 'registry') {
            paths.remove(k);
        }
    }
    return paths[0] if paths else [];
}