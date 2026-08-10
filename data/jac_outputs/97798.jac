"""Returns a triple of the options: a key field type, a value
    field type, and a flag of needs of output generation."""
def _get_options(opts: Any, with_keyty_valty: Any) -> object {
    if (not with_keyty_valty and (("key" in opts) or ("value" in opts))) {
        raise Exception("Bad option: key= or value= not allowed");
    }
    keyty = opts.get("key", "opaque");
    valty = opts.get("value", "opaque");
    mkkvo = opts.get("output", True);
    return (keyty, valty, mkkvo);
}