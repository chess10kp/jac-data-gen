def example() {
    numbers = [1, 2, 3, 4, 5, 6, 7, 8];

    # Using lambdas in pipe chains
    result = numbers
        |> (lambda x: list : [i * 2 for i in x])
        |> (lambda x: list : [i for i in x if i > 10])
        |> sum;
}
