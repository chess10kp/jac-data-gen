def find_type(x: Any) -> object {
    type_dict = {"a": "alpha", "b": "beta", "c": "gamma"};
    return type_dict.get(x, "unknown");
}



with entry {
    print(find_type('hello'));
}
