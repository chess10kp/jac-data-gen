import from json { dumps }

def serialize(data: dict) -> str {
    return dumps(data);
}

def sum_squares(n: int) -> int {
    total = 0;
    for i in range(n) {
        total += i * i;
    }
    return total;
}

with entry {
    result = sum_squares(1000);
    print(f"Sum of squares: {result}");
}
