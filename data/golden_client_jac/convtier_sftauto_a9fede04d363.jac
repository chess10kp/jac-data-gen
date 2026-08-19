def compress_string(string: Any) -> object {
    compressed_string = "";
    count = 1;
    for i in range(1, len(string)) {
        if (string[i] == string[(i - 1)]) {
            count += 1;
        } else {
            compressed_string += string[(i - 1)] + str(count);
            count = 1;
        }
    }
    compressed_string += string[-1] + str(count);
    return compressed_string;
}



with entry {
    print(compress_string('hello'));
    print(compress_string('Racecar'));
    print(compress_string('abcabc'));
}
