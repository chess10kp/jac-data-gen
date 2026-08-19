def replace_python_with_java(text: Any) -> object {
    words = text.split();
    for i in range(len(words)) {
        if (words[i] == 'Python') {
            if (
                (i == 0)
                or (i == (len(words) - 1))
                or (not words[(i - 1)].isalpha() and not words[(i + 1)].isalpha())
            ) {
                words[i] = 'Java';
            }
        }
    }
    modified_text = ' '.join(words);
    return modified_text;
}



with entry {
    print(replace_python_with_java('hello'));
    print(replace_python_with_java('Racecar'));
    print(replace_python_with_java('abcabc'));
}
