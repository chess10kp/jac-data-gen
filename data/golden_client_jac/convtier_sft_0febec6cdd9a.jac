obj MathUtil {
    static def square(x: int) -> int { return x * x; }
}

with entry {
    print(MathUtil.square(5));
}
