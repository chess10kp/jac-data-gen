def retrieve_last_three_unique_elements(arr: Any) -> object {
    if (len(arr) < 3) {
        return arr;
    }
    unique_elements = [];
    for i in range((len(arr) - 1), -1, -1) {
        if (arr[i] not in unique_elements) {
            unique_elements.append(arr[i]);
            if (len(unique_elements) == 3) {
                break;
            }
        }
    }
    return sorted(unique_elements);
}



with entry {
    print(retrieve_last_three_unique_elements('hello'));
    print(retrieve_last_three_unique_elements('Racecar'));
    print(retrieve_last_three_unique_elements('abcabc'));
}
