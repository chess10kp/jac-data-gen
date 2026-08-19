def reverse(arr: Any) -> object {
    result = [];
    for i in range((len(arr) - 1), -1, -1) {
        if (arr[i] not in result) {
            result.append(arr[i]);
        }
    }
    return result;
}



with entry {
    print(reverse('hello'));
    print(reverse('Racecar'));
    print(reverse('abcabc'));
}
