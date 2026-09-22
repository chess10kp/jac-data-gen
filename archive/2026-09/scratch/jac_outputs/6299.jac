""" Convert augs to int or return empty """
def args_to_int(args: list[str]) -> tuple[int, ...] {
    try {
        return tuple([int(i) for i in args]);
    } except ValueError {
        return ();
    }
}