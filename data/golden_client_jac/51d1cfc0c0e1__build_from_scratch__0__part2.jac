def base3(n: int) -> str {
    if n == 0 {
        return "0";
    }
    s = "";
    while n > 0 {
        s = str(n % 3) + s;
        n = n // 3;
    }
    return s;
}

with entry {
    for x in [0, 1, 3, 10, 26] {
        print(base3(x));
    }
}
