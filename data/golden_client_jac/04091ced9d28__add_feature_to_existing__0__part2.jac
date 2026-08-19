def expensive_computation -> int {
    return 42;
}

def do_something_else -> int {
    return 1;
}

# New background task added
def secondary_computation -> int {
    return 8;
}

with entry {
    future = flow expensive_computation();
    future2 = flow secondary_computation();

    other_result = do_something_else();

    result = wait future;
    result2 = wait future2;
    print(f"{result} + {result2} + {other_result}");
}
