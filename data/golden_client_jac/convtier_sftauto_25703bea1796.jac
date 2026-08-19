def produce_negative_output(n: Any) -> object {
    if (n == 1) {
        return -1;
    } elif (n == 2) {
        return -2;
    } else {
        return (produce_negative_output((n - 1)) - produce_negative_output((n - 2)));
    }
}



with entry {
    print(produce_negative_output(2));
    print(produce_negative_output(1));
}
