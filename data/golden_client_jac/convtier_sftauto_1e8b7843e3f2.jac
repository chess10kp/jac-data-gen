def generate_array(n: Any) -> object {
    if (n == 1) {
        return [1];
    } else {
        return ([n] + generate_array((n - 1)));
    }
}



with entry {
    print(generate_array(1));
}
