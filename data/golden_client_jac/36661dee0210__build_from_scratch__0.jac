with entry {
    adder = (def make_adder(x: int) {
        return lambda y: int : x + y;
    })(10);

    print(adder(5));   # expect 15
}
