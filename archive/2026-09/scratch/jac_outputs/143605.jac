"""Calls function passed as argument zero and ignores any exceptions raised by it."""
def ignore(*args: object) -> object | None {
    try {
        return args[0](*args[1:]);
    } except Exception {
        ;
    }
}