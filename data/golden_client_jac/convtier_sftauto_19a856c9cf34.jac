def find_odd_number(arr: Any) -> object {
    count = {};
    for num in arr {
        if (num in count) {
            count[num] += 1;
        } else {
            count[num] = 1;
        }
    }
    for num in arr {
        if ((count[num] % 2) == 1) {
            return num;
        }
    }
    return -1;
}



with entry {
    print(find_odd_number('hello'));
    print(find_odd_number('Racecar'));
    print(find_odd_number('abcabc'));
}
