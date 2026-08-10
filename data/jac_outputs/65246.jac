glob DOCTOC_START = "<!-- START doctoc generated TOC please keep comment here to allow auto update -->";
glob DOCTOC_END = "<!-- END doctoc generated TOC please keep comment here to allow auto update -->";

"""Strip out doctoc Table of Contents for RippleAPI"""
def filter_markdown(md: str, **kwargs: object) -> str {
    doctoc_start_i = md.find(DOCTOC_START);
    doctoc_end_i = md.find(DOCTOC_END);
    if doctoc_start_i != -1 and doctoc_end_i != -1 {
        md = md[:doctoc_start_i] + md[doctoc_end_i + len(DOCTOC_END):];
    }
    return md;
}