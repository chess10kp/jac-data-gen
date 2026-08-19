def compress_string(s: Any) -> object {
    compressed = '';
    count = 1;
    for i in range(1, len(s)) {
        if (s[i] == s[(i - 1)]) {
            count += 1;
        } else {
            compressed += (s[(i - 1)] + str(count)) if (count > 1) else s[(i - 1)];
            count = 1;
        }
        if (count == 10) {
            compressed += s[(i - 1)] + str(count);
            count = 1;
        }
    }
    compressed += (s[-1] + str(count)) if (count > 1) else s[-1];
    return compressed;
}



with entry {
    print(compress_string('hello'));
    print(compress_string('Racecar'));
    print(compress_string('abcabc'));
}
