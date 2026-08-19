def retrieve_elements(arr: Any) -> object {
    count_dict = {};
    for elem in arr {
        if (elem not in count_dict) {
            count_dict[elem] = 1;
        } else {
            count_dict[elem] += 1;
        }
    }
    result = [];
    for elem in arr {
        if (count_dict[elem] == 1) {
            result.append(elem);
        }
    }
    return result;
}



with entry {
    print(retrieve_elements('hello'));
    print(retrieve_elements('Racecar'));
    print(retrieve_elements('abcabc'));
}
