def print_names(data: Any) -> object {
    names = [];
    for `obj in data {
        name = `obj.get("name");
        if (name is None) {
            names.append("Unknown");
        } elif (name == "") {
            names.append("Empty");
        } else {
            names.append(name);
        }
    }
    return names;
}



with entry {
    print(print_names([]));
}
