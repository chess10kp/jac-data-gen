def describe_sign(n: int) {
    if n > 0 { print("positive"); }
}
with entry {
    x = 5;
    print(x);
    describe_sign(x);
}
