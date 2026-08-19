def example() -> int {
    if True {
        block_var = 42;
    }

    for i in range(3) {
        loop_var = i;
    }

    # New: both block_var and loop_var remain in scope here
    return block_var + loop_var;
}

with entry {
    print(example());
}
