def my_function(x: Any) -> object {
    while ((x > 1000) and ((x % 3) == 0)) {
        x += 1;
    }
    return x;
}



with entry {
    print(my_function(5));
    print(my_function(10));
    print(my_function(2));
}
