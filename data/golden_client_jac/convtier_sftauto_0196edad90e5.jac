def remove_duplicates_palindromes(arr: Any) -> object {
    result = [];
    seen = `set();
    for word in arr {
        if ((word == word[::-1]) and (word not in seen)) {
            result.append(word);
            seen.add(word);
        }
    }
    return result;
}



with entry {
    print(remove_duplicates_palindromes('hello'));
    print(remove_duplicates_palindromes('Racecar'));
    print(remove_duplicates_palindromes('abcabc'));
}
