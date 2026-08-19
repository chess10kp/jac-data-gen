def create_dict(lst: Any) -> object {
    `dict = {};
    for i in range(len(lst)) {
        if ((lst[i] % 2) == 0) {
            if (lst[i] in `dict) {
                `dict[lst[i]] = `dict[lst[i]] ** 2;
            } else {
                `dict[lst[i]] = lst[i] ** 2;
            }
        }
    }
    return `dict;
}



with entry {
    print(create_dict([]));
    print(create_dict([-12, 6]));
    print(create_dict([-12, -6, -3, 21]));
}
