def f(arr: Any) -> object {
    n = len(arr);
    new_arr = [0] * n;
    for i in range(1, n) {
        new_arr[(i - 1)] = arr[i];
    }
    new_arr.pop();
    return new_arr;
}



with entry {
    print(f('hello'));
    print(f('Racecar'));
    print(f('abcabc'));
}
