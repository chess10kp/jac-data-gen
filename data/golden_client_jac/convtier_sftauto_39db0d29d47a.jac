def count_elements(arr: Any) -> object {
    unique_arr = [];
    for num in arr {
        if (num not in unique_arr) {
            unique_arr.append(num);
        }
    }
    counts = {};
    for num in unique_arr {
        counts[num] = arr.count(num);
    }
    return counts;
}



with entry {
    print(count_elements('hello'));
    print(count_elements('Racecar'));
    print(count_elements('abcabc'));
}
