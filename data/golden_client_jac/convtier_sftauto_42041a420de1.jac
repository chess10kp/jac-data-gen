def find_smallest(arr: Any) -> object {
    smallest = arr[0];
    for num in arr {
        if (num < smallest) {
            smallest = num;
        }
    }
    return smallest;
}



with entry {
    print(find_smallest('hello'));
    print(find_smallest('Racecar'));
    print(find_smallest('abcabc'));
}
