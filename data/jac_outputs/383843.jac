"""A diff function for autocorrect that determines how many letters
    in START need to be substituted to create GOAL, then adds the difference in
    their lengths.
    """
def swap_diff(start: Any, goal: Any, limit: Any) -> object {
    def helper_function(tally: Any, i: Any) -> object {
        if (limit < tally) {
            return tally;
        } elif ((len(goal) == i) or (len(start) == i)) {
            return (tally + abs((len(start) - len(goal))));
        } elif (goal[i] == start[i]) {
            return helper_function(tally, (i + 1));
        } else {
            return helper_function((tally + 1), (i + 1));
        }
    }
    return helper_function(0, 0);
}