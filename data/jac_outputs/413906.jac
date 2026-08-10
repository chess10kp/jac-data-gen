"""Attempts to take the arguments in arg and kwargs and return only those which can be used
       by the argspec given."""
def conform_to_argspec(
    args: tuple[object, ...],
    kwargs: dict[str, object],
    argspec: tuple[list[str], str | None, str | None, tuple[object, ...] | None]
) -> tuple[list[object], dict[str, object]] {
    (regargs, varargs, varkwargs, defaults) = argspec;
    N = len(regargs);
    newargs = list(args);
    newkwargs = kwargs.copy();
    if varargs is None {
        newargs = newargs[:N];
    }
    for varname in regargs[len(newargs):] {
        try {
            newargs.append(newkwargs[varname]);
            del newkwargs[varname];
        } except KeyError {
            break;
        }
    }
    if varkwargs is None {
        newkwargs = {};
    }
    return (newargs, newkwargs);
}