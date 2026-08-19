def remove_divisible_by_4(arr: Any) -> object {
    if not `any(((num % 4) == 0) for num in arr) {
        raise ValueError("No numbers divisible by 4 found");
    }
    arr = [
        num
        for num in arr
        if ((num % 4) != 0)
    ];
    arr.sort();
    return arr;
}



with entry {
    print(remove_divisible_by_4([10, 20, 30]));
    print(remove_divisible_by_4([2, 4, 6, 8]));
    print(remove_divisible_by_4([4, 2, 7, 1, 9]));
}
