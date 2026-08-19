def describe_sign(n: int) -> None {
    if n > 0 {
        print("positive");
    }
}
with entry {
    x = 5;
    print(x);
    describe_sign(x);
}
