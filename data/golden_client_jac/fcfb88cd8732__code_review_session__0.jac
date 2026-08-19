import from typing { Generator }

def count_up(n: int) -> Generator[int, None, None] {
    for i in range(n) {
        yield i;
    }
}

with entry {
    for num in count_up(5) {
        print(num);  # 0, 1, 2, 3, 4
    }
}
