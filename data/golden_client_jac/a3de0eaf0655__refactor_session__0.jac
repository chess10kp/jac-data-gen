def squares_loop(n: int) -> list {
    result = [];
    for i = 0 to i < n by i += 1 {
        result.append(i ** 2);
    }
    return result;
}

def squares_comp(n: int) -> list {
    return [i ** 2 for i in range(n)];
}

def evens(n: int) -> list {
    return [i for i in range(n) if i % 2 == 0];
}

with entry {
    print(squares_loop(5));
    print(squares_comp(5));
    print(evens(10));
}
