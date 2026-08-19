glob rng: int = 987654321;

def rand01 -> float {
    rng = (rng * 1103515245 + 12345) % 2147483648;
    return rng / 2147483648.0;
}
