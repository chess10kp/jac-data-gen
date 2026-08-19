glob rng: int = 987654321;

def rand01 -> float {
    global rng;
    rng = (rng * 1103515245 + 12345) % 2147483648;
    return float(rng) / 2147483648.0;
}

with entry {
    for _i in range(6) {
        print(str(round(rand01(), 9)));
    }
}
