def hello_world_n_times(n: Any) -> object {
    if (not isinstance(n, int) or (n <= 0)) {
        raise ValueError("n must be a positive integer");
    }
    return ("Hello World!" * n);
}



with entry {
    print(hello_world_n_times(5));
    print(hello_world_n_times(10));
    print(hello_world_n_times(2));
}
