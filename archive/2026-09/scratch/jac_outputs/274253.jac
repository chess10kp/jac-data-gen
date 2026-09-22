"""Constructs stock and flow chains that implement the calculation of a smoothing function."""
def add_n_smooth(
    identifier: str,
    smooth_input: str,
    smooth_time: str,
    initial_value: str,
    order: str,
    subs: list[str],
    subscript_dict: dict[str, str]
) -> tuple[str, list[dict[str, str]]] {
    stateful = {
        'py_name': ('_smooth_%s' % identifier),
        'real_name': ('Smooth of %s' % smooth_input),
        'doc': (
            'Smooth time: %s \n Smooth initial value %s \n Smooth order %s'
            % (smooth_time, initial_value, order)
        ),
        'py_expr': (
            'functions.Smooth(lambda: %s, lambda: %s, lambda: %s, lambda: %s)'
            % (smooth_input, smooth_time, initial_value, order)
        ),
        'unit': 'None',
        'lims': 'None',
        'eqn': 'None',
        'subs': '',
        'kind': 'stateful',
        'arguments': ''
    };
    return (('%s()' % stateful['py_name']), [stateful]);
}