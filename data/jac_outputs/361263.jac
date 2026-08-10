"""Try really hard to scale 'points' by 'scalar'.

    @type  points: mixed
    @param points: Points can either be:

        - a sequence of pairs, in which case the second item will be scaled,
        - a list, or
        - a number

    @type  scalar: number
    @param scalar: the amount to multiply points by
    """
def scale(points: Any, scalar: Any) -> object {
    if (`type(points) is `list) {
        try {
            return [(k, (p * scalar)) for (k, p) in points];
        } except TypeError {
            return [(p * scalar) for p in points];
        }
    } else {
        return (points * scalar);
    }
}