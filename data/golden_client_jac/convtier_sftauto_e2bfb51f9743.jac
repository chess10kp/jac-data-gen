def delete_and_sort(list1: Any) -> object {
    result = [];
    target = 4;
    for num in list1 {
        if (num != target) {
            result.append(num);
        }
    }
    result.sort();
    return result;
}



with entry {
    print(delete_and_sort('hello'));
    print(delete_and_sort('Racecar'));
    print(delete_and_sort('abcabc'));
}
