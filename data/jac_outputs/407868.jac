"""Convert a string of comma separated numbers to a tuple of integers"""
def int_tuple(arg: str) -> tuple[int, ...] {
    args = arg.split(',');
    try {
        return tuple([int(e) for e in args]);
    } except ValueError {
        raise ValueError(
            'Expected a comma separated list of integers, found %s' % arg
        );
    }
}