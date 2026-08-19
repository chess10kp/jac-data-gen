def compare_username(username: Any) -> object {
    if username.startswith("John") {
        return 0;
    } elif ("John" in username) {
        return -1;
    } else {
        return 1;
    }
}



with entry {
    print(compare_username('hello'));
}
