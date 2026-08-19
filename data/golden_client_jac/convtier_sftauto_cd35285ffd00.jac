def compress_string(s: Any) -> object {
    compressed = "";
    count = 1;
    for i in range(len(s)) {
        if ((i < (len(s) - 1)) and (s[i] == s[(i + 1)])) {
            count += 1;
        } else {
            compressed += s[i] + str(count);
            count = 1;
        }
    }
    return compressed;
}



with entry {
    print(compress_string('hello'));
    print(compress_string('Racecar'));
    print(compress_string('abcabc'));
}
