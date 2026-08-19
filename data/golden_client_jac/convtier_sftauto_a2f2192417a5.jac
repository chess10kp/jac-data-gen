def generate_list(num: Any) -> object {
    result = [];
    for i in range((num + 1)) {
        if (((i % 3) != 0) and ((i % 5) != 0)) {
            result.append(i);
        }
    }
    result.sort(reverse=True);
    return result;
}



with entry {
    print(generate_list(5));
    print(generate_list(10));
    print(generate_list(2));
}
