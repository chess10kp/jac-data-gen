def count_occurrences(string: Any) -> object {
    words = string.split();
    count = 0;
    for i in range((len(words) - 1)) {
        if (
            (words[i].lower() == 'python') and (words[(i + 1)].lower() == 'programming')
        ) {
            if ((words[i] + words[(i + 1)]) == 'Pythonprogramming') {
                count += 1;
            }
        }
    }
    return count;
}



with entry {
    print(count_occurrences('hello'));
}
