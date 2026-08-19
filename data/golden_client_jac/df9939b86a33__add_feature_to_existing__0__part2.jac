def timing(f: any) -> any {
    return f;
}

# New decorator that tags a function as cached
def cache(f: any) -> any {
    return f;
}

@timing
def expensive_operation -> int {
    return 42;
}

@timing
@cache
def cached_operation -> int {
    return 7;
}

with entry {
    print(expensive_operation());
    print(cached_operation());
}
