def get_data_type(value: Any) -> object {
    if isinstance(value, bool) {
        return 'boolean';
    } elif isinstance(value, int) {
        return 'integer';
    } elif isinstance(value, str) {
        return 'string';
    } elif isinstance(value, `list) {
        return 'array';
    } elif (value is None) {
        return 'null';
    } else {
        return 'object';
    }
}



with entry {
    print(get_data_type('hello'));
    print(get_data_type(5));
    print(get_data_type([]));
}
