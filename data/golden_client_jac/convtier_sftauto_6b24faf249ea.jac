def get_palindromes(strings: Any) -> object {
    palindromes = [];
    for string in strings {
        modified_string = re.sub(r'[^a-zA-Z0-9]', '', string.lower());
        if (modified_string == modified_string[::-1]) {
            palindromes.append(string);
        }
    }
    return palindromes;
}



with entry {
    print(get_palindromes([]));
}
