def compute_median(numbers: Any) -> object {
    return int(sorted(numbers)[(len(numbers) // 2)])
        if (len(numbers) % 2)
        else int(
            (
                sum(
                    sorted(numbers)[((len(numbers) // 2) - 1):((len(numbers) // 2) + 1)]
                ) / 2
            )
        );
}



with entry {
    print(compute_median([0]));
    print(compute_median([2, -4, -8]));
    print(compute_median([7, -1, -4, -2]));
}
