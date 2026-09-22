"""Constructs an xpath matching element with tag containing content."""
def tag_contents_xpath(tag: str, content: str) -> str {
    content = content.lower();
    return '//{}[contains(translate(*,"ABCDEFGHIJKLMNOPQRSTUVWXYZ","abcdefghijklmnopqrstuvwxyz"),"{}")]'.format(
        tag, content
    );
}