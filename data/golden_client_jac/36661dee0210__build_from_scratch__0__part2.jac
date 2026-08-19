with entry {
    adder = (def make_adder(x: int) -> any {
        return lambda y: int : x + y;
    })(10);

    print(adder(5));   # 15
}
