def handle_animal(input: Any) -> object {
    switcher = {"cat": "Meow!", "dog": "Woof!", "mouse": "Squeak!", "rabbit": "Hop!"};
    return switcher.get(input, "Unknown animal");
}



with entry {
    print(handle_animal('hello'));
}
