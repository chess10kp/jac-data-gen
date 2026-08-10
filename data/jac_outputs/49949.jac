"""Funtion to filter out timestamps (e.g. 08:30) and websites (e.g. http://site.com)"""
def filter_colons(part: str) -> list[str] {
    new_parts: list[str] = [];
    split_part = part.split(':');
    for (idx, segment) in enumerate(split_part) {
        if idx == 0 {
            new_parts.append(segment);
        } elif segment[0].isalpha() {
            new_parts.append(segment);
        } else {
            new_parts[-1] += ':' + segment;
        }
    }
    return new_parts;
}