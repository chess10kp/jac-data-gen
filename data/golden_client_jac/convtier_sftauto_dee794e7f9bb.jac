def get_unique_permutations(string: Any) -> object {
    if (len(string) <= 1) {
        return [string];
    }
    permutations = [];
    for i in range(len(string)) {
        for perm in get_unique_permutations((string[:i] + string[(i + 1):])) {
            if (perm.count(string[i]) < 2) {
                permutations.append((string[i] + perm));
            } elif ((perm.count(string[i]) == 1) and (perm[-1] != string[i])) {
                permutations.append((string[i] + perm));
            }
        }
    }
    return `list(`set(permutations));
}



with entry {
    print(get_unique_permutations([0]));
    print(get_unique_permutations([]));
    print(get_unique_permutations(['a']));
}
