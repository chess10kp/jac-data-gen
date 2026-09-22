"""sl is list of sources in form: ns:id.  Return
    the ns and id of the last entry"""
def get_source_id(sl: list[str]) -> tuple[str, str] {
    source = sl[-1];
    (ns, id) = source.split(':');
    return (ns, id);
}