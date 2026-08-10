"""
simple function to remove the elements token from a tag name

e.g. tag_only('tag_name{10}') -> 'tag_name'
"""
def tag_only(tag: str) -> str {
    if '{' in tag {
        return tag[:tag.find('{')];
    }
    return tag;
}