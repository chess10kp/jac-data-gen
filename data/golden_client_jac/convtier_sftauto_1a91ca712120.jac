def generate_array(n: Any) -> object {
    unique_set = `set();
    while (len(unique_set) < n) {
        unique_set.add(random.randint(0, 100));
    }
    array = sorted(`list(unique_set), reverse=True);
    return array;
}



with entry {
    print(generate_array(0));
}
