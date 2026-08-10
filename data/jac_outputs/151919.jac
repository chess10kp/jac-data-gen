""" Convert the stack dumps and sample counts into the flamegraph format.

    Return a list of lines.
    """
def to_flamegraph(stacks: Any, counts: Any) -> object {
    lines = [];
    for id in counts {
        stack = ";".join(reversed(stacks[id]));
        count = counts[id];
        lines.append('{0} {1}'.format(stack, count));
    }
    return lines;
}