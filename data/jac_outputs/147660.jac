""" interpret input distribution descriptions into usable entries """
def interpret_distribution(key: Any, value: Any) -> object {
    (dist_name, args) = value.split('(');
    dist_name = dist_name.strip();
    args = args.strip(')').split(',');
    converted = {};
    if (dist_name not in ['uniform', 'normal', 'constant']) {
        raise IOError(
            (
                'Variable distributions can only be "uniform", "normal", or "constant"; '
                + 'got "{}" for "{}"'.format(dist_name, key)
            )
        );
    }
    converted['dist'] = dist_name;
    if (dist_name == 'uniform') {
        converted['lowerBound'] = float(args[0]);
        converted['upperBound'] = float(args[1]);
    } elif (dist_name == 'normal') {
        converted['mean'] = float(args[0]);
        converted['std'] = float(args[1]);
        if (len(args) > 2) {
            converted['lowerBound'] = float(args[2]);
            converted['upperBound'] = float(args[3]);
        }
    } elif (dist_name == 'constant') {
        converted['value'] = float(args[0]);
    }
    return converted;
}