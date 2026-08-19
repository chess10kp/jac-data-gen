import from typing { Generator }

def fibonacci(max_value: int) -> Generator[int, None, None] {
    a = 0;
    b = 1;
    while a < max_value {
        yield a;
        (a, b) = (b, a + b);
    }
}

with entry {
    for n in fibonacci(20) {
        print(n);  # 0 1 1 2 3 5 8 13
    }
}
