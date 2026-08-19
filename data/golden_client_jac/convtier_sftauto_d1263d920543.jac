def fibonacci(index: Any) -> object {
    if (index <= 0) {
        return 0;
    } elif (index == 1) {
        return 1;
    } else {
        return (fibonacci((index - 1)) + fibonacci((index - 2)));
    }
}



with entry {
    print(fibonacci(0));
    print(fibonacci(1));
}
