def decorator(func: object) -> object {
    def wrapper(*args: object, **kwargs: object) -> object {
        print("calling");
        return func(*args, **kwargs);
    }
    return wrapper;
}

def decorator_with_args(arg1: object, arg2: object) -> object {
    return lambda func: object : func;
}

@decorator
def my_function -> None {
    print("decorated");
}

@decorator_with_args("a", "b")
def another_function -> None {
    print("decorated with args");
}
