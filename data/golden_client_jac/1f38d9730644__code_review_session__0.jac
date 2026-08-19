def example() -> int {
    numbers = [1, 2, 3, 4, 5, 6, 7, 8];
    result = numbers
        |> (lambda x: list : [i * 2 for i in x])
        |> (lambda x: list : [i for i in x if i > 10])
        |> sum;
    return result;
}
