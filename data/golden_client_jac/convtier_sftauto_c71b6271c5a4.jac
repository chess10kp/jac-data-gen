def move_zeros(arr: Any) -> object {
    non_zeros = [
        num
        for num in arr
        if (num != 0)
    ];
    zeros = [0] * (len(arr) - len(non_zeros));
    return (non_zeros + zeros);
}



with entry {
    print(move_zeros('hello'));
    print(move_zeros('Racecar'));
    print(move_zeros('abcabc'));
}
