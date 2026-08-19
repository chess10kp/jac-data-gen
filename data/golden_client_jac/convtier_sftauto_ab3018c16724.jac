def remove_duplicates_reverse(lst: Any) -> object {
    seen = `set();
    result = [];
    for i in range((len(lst) - 1), -1, -1) {
        if (lst[i] not in seen) {
            seen.add(lst[i]);
            result.append(lst[i]);
        }
    }
    return result;
}



with entry {
    print(remove_duplicates_reverse('hello'));
    print(remove_duplicates_reverse('Racecar'));
    print(remove_duplicates_reverse('abcabc'));
}
