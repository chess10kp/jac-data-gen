"""
    Verifica se ci sono argument con la classe.
    """
def has_argument(arg: Any, arguments: Any) -> object {
    try {
        if not isinstance(arguments, `list) {
            arguments = arguments.__arguments__;
        }
        for (idx, (args, kwargs)) in enumerate(arguments) {
            arg_name = kwargs.get('dest', args[-1].lstrip('-').replace('-', '_'));
            if (arg_name == arg) {
                return idx;
            }
        }
        idx = False;
    } except (ValueError, AttributeError) {
        idx = False;
    }
    return idx;
}