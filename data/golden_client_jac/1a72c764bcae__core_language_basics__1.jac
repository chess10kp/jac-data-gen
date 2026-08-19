def example() {
    if True {
        block_var = 42;    # Created in block
    }
    # block_var is still accessible here in Jac (unlike some languages)

    for i in range(3) {
        loop_var = i;
    }
    # loop_var and i are accessible here
}
