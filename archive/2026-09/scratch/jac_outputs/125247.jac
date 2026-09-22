"""Remove non text unicode characters; maybe some could hint at parsing?."""
def sanitize(lines: list[str]) -> list[str] {
    return [
        line.replace('\u202b', '').replace('\u202c', '').replace('\x0c', '')
        for line in lines
    ];
}