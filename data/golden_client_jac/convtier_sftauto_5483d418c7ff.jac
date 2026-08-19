def recursive_function(n: Any) -> object {
    if (n == 0) {
        return "Termination condition reached";
    } elif (n < 0) {
        raise ValueError("Input must be a positive integer");
    } else {
        try {
            return recursive_function((n - 1));
        } except ValueError as error {
            return str(error);
        }
    }
}



with entry {
    print(recursive_function(0));
}
