def create_list(length: Any) -> object {
    new_list = [];
    negative_count = 0;
    while (len(new_list) < length) {
        num = random.randint(-1000, 1000);
        if (num < 0) {
            if (negative_count >= 7) {
                continue;
            }
            negative_count += 1;
        }
        if (num not in new_list) {
            new_list.append(num);
        }
    }
    return new_list;
}



with entry {
    print(create_list(0));
}
