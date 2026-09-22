"""Utility function to help preparing Coursera grading conditions descriptions.
Args:
   array: iterable of numbers, the correct answers
   epslion: the generated expression will accept the answers with this absolute difference with
     provided values
Returns:
   String. A Coursera grader expression that checks whether the user submission is in
     (array - epsilon, array + epsilon)"""
def array_to_grader(array: list[int | float], epsilon: float = 0.0001) -> str {
    res = [];
    for element in array {
        if isinstance(element, int) {
            res.append("[{0}, {0}]".format(element));
        } else {
            res.append("({0}, {1})".format(element - epsilon, element + epsilon));
        }
    }
    return " ".join(res);
}