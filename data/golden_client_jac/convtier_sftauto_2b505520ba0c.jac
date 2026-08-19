def find_first_repeating(arr: Any) -> object {
    count_dict = {};
    for num in arr {
        if (num in count_dict) {
            count_dict[num] += 1;
        } else {
            count_dict[num] = 1;
        }
    }
    for num in arr {
        if (count_dict[num] > 1) {
            return num;
        }
    }
    return -1;
}



with entry {
    print(find_first_repeating('hello'));
    print(find_first_repeating('Racecar'));
    print(find_first_repeating('step on no pets'));
}
