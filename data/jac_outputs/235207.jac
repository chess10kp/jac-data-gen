"""Convert string argument to a slice."""
def flexdefault(arg: object) -> object {
    if isinstance(arg, str) {
        arg = eval(('np.s_[' + arg + ']'));
    }
    return [arg] if isinstance(arg, int) else arg;
}