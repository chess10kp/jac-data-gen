glob make_adder = lambda x: int : (lambda y: int : x + y);

with entry {
    add_five = make_adder(5);
    print(add_five(10));   # 15
}
