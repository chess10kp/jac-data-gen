def recursive_add(numbers: Any) -> object {
    if (len(numbers) == 1) {
        return numbers[0];
    } else {
        return (numbers[0] + recursive_add(numbers[1:]));
    }
}



with entry {
    print(recursive_add([81]));
    print(recursive_add(['a']));
    print(recursive_add([100]));
}
