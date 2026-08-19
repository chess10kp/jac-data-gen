def delete_duplicates(arr: Any) -> object {
    i = 0;
    while (i < (len(arr) - 1)) {
        if (arr[i] == arr[(i + 1)]) {
            delete(arr[(i + 1)],);
        } else {
            i += 1;
        }
    }
    return arr;
}



with entry {
    print(delete_duplicates('Racecar'));
    print(delete_duplicates('abcabc'));
    print(delete_duplicates('level'));
}
