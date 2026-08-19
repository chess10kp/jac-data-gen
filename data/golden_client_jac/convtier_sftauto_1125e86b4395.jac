def set_result(bool1: Any) -> object {
    if (bool1 == False) {
        result = 0;
    } else {
        result = 1;
    }
    return result;
}



with entry {
    print(set_result('hello'));
    print(set_result(0));
}
