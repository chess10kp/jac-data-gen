def compute_hash_code(string: Any) -> object {
    hash_code = 0;
    prime = 31;
    for char in string {
        hash_code += ord(char);
    }
    hash_code = hash_code % prime;
    return hex(hash_code)[2:];
}



with entry {
    print(compute_hash_code('hello'));
    print(compute_hash_code('Racecar'));
    print(compute_hash_code('abcabc'));
}
