def is_numeric(element: Any) -> object {
    try {
        float(element);
        return True;
    } except ValueError {
        return False;
    }
}



with entry {
    print(is_numeric('hello'));
    print(is_numeric(5));
}
