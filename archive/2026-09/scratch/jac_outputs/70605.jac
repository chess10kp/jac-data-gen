"""Extract tags from given tagline"""
def get_tags_gff3(tagline: str) -> dict[str, str] {
    tags = dict();
    for t in tagline.strip(';').split(';') {
        tt = t.split('=');
        tags[tt[0]] = tt[1];
    }
    return tags;
}