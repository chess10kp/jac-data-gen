def process_integers(integers: Any) -> object {
    new_list = [];
    for integer in integers {
        if ((integer % 4) == 0) {
            new_list.append(((integer * 3) - 2));
        } elif ((integer % 6) == 0) {
            new_list.append(((integer / 3) + 2));
        } elif ((integer % 9) == 0) {
            new_list.append((integer + 7));
        } else {
            new_list.append((integer + 4));
        }
    }
    return new_list;
}



with entry {
    print(process_integers([81]));
    print(process_integers([]));
    print(process_integers([100]));
}
