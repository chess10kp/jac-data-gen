def switch_string(str: Any) -> object {
    length = len(str);
    if ((length % 2) == 1) {
        index = length // 2;
    } else {
        index = (length // 2) + 1;
    }
    part1 = str[:index];
    part2 = str[index:];
    return (part2 + part1);
}



with entry {
    print(switch_string('hello'));
    print(switch_string('Racecar'));
    print(switch_string('abcabc'));
}
