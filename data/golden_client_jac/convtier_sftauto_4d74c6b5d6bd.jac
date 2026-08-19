def greet(name: Any) -> object {
    if (not name or not name.isalpha() or (len(name) > 20)) {
        return "Invalid name!";
    }
    return ("Hello " + name + "!");
}



with entry {
    print(greet('hello'));
    print(greet('Racecar'));
    print(greet('abcabc'));
}
