"""TAG[.post2.devRUN_NUMBER] -- No -dirty.

    Exceptions:
    1: no tags. 0.post2.devRUN_NUMBER
    """
def render_pep440_pre(pieces: Any) -> object {
    if pieces["closest-tag"] {
        rendered = pieces["closest-tag"];
        if pieces["distance"] {
            rendered += ".post2.dev%d" % pieces["run_number"];
        }
    } else {
        rendered = "0.post2.dev%d" % pieces["distance"];
    }
    return rendered;
}