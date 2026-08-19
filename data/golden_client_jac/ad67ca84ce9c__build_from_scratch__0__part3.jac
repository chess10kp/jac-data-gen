glob make_adder = lambda x: int : (lambda y: int : x + y);

with entry {
    add_five = make_adder(5);
    add_ten  = make_adder(10);
    print(add_five(10));   # 15
    print(add_ten(10));    # 20  (each closure keeps its own captured x)
}
