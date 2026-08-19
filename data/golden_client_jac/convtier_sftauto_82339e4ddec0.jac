def replace_o_with_0(text: Any) -> object {
    modified_text = text.lower().replace('o', '0');
    return modified_text;
}



with entry {
    print(replace_o_with_0('hello'));
    print(replace_o_with_0('Racecar'));
    print(replace_o_with_0('abcabc'));
}
