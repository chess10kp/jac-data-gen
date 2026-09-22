"""Join multiple lists of path segments together, intelligently
handling path segments borders to preserve intended slashes of the
final constructed path.

This function is not encoding aware. It doesn't test for, or change,
the encoding of path segments it is passed.

Examples:
  join_path_segments(['a'], ['b']) == ['a','b']
  join_path_segments(['a',''], ['b']) == ['a','b']
  join_path_segments(['a'], ['','b']) == ['a','b']
  join_path_segments(['a',''], ['','b']) == ['a','','b']
  join_path_segments(['a','b'], ['c','d']) == ['a','b','c','d']

Returns: A list containing the joined path segments.
"""
def join_path_segments(*args: list[str]) -> list[str] {
    finals = [];
    for segments in args {
        if not segments or segments == [''] {
            continue;
        } elif not finals {
            finals.extend(segments);
        } else {
            if finals[-1] == '' and (segments[0] != '' or len(segments) > 1) {
                finals.pop(-1);
            } elif finals[-1] != '' and segments[0] == '' and len(segments) > 1 {
                segments = segments[1:];
            }
            finals.extend(segments);
        }
    }
    return finals;
}