def sum_of_positive_integers(arr: Any) -> object {
    return sum(
        [
            num
            for num in arr
            if (num > 0)
        ]
    );
}



with entry {
    print(sum_of_positive_integers([]));
}
