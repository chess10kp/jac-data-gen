def count_lowercase(str: Any) -> object {
    if (len(str) == 0) {
        return 0;
    } elif (str[0] == 'a') {
        return count_lowercase(str[1:]);
    } elif str[0].islower() {
        return (1 + count_lowercase(str[1:]));
    } else {
        return count_lowercase(str[1:]);
    }
}



with entry {
    print(count_lowercase([]));
}
