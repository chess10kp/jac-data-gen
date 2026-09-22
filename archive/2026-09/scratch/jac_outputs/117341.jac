"""Join multiple list of path segments

    This function is not encoding aware, it does not test for, or changed the
    encoding of the path segments it's passed.
    """
def join_path_segments(*args: list[str]) -> list[str] {
    finals = [];
    for segments in args {
        if not segments or segments[0] == [''] {
            continue;
        } elif not finals {
            finals.extend(segments);
        } else {
            if finals[-1] == '' and (segments[0] != '' or len(segments) > 1) {
                finals.pop(-1);
            } elif finals[-1] != '' and segments[0] == '' and len(segments) > 1 {
                segments.pop(0);
            }
            finals.extend(segments);
        }
    }
    return finals;
}