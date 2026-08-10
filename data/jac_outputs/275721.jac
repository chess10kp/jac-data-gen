"""Get the name of an object.

    For use in case of callables that are not functions, and
    thus may not have __name__ defined.

    Order: f.__name__ >  f.name > str(f)
    """
def getname(f: Any) -> object {
    try {
        return f.__name__;
    } except Exception as e {
        ;
    }
    try {
        return f.name;
    } except Exception as e {
        ;
    }
    return str(f);
}