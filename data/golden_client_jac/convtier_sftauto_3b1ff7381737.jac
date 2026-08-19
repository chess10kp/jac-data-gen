def encode_byte_sequence(output: Any) -> object {
    byte_sequence = [];
    for char in output {
        byte_sequence.extend(char.encode('utf-8'));
    }
    return byte_sequence;
}



with entry {
    print(encode_byte_sequence('hello'));
    print(encode_byte_sequence('Racecar'));
    print(encode_byte_sequence('abcabc'));
}
