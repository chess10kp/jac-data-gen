def sum(numbers: Any) -> object {
    x = 0;
    for n in numbers {
        x += n;
        if (x > 100) {
            return -1;
        }
    }
    return x;
}



with entry {
    print(sum([]));
}
