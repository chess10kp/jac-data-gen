"""Return XML element bare tag name (without prefix)"""
def xmltag_split(tag: str) -> str {
    try {
        return tag.split('}')[1];
    } except Exception {
        return tag;
    }
}