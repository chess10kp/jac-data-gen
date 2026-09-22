"""filter for valid 80-char observation records"""
def is_ob(x: tuple[object, ...] | list[object]) -> bool {
    return not isinstance(x[0], Exception);
}