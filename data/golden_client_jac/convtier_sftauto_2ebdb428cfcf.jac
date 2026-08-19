def find_single_occurrence_index(arr: Any) -> object {
    counts = {};
    for element in arr {
        if (element in counts) {
            counts[element] += 1;
        } else {
            counts[element] = 1;
        }
    }
    for i in range(len(arr)) {
        if (counts[arr[i]] == 1) {
            return i;
        }
    }
}



with entry {
    print(find_single_occurrence_index('hello'));
    print(find_single_occurrence_index('level'));
}
