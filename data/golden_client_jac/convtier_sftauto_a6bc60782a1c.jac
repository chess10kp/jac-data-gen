def remove_punctuation(string: Any) -> object {
    if not string {
        return "";
    }
    cleaned_string = re.sub(r'[^\w\s]', '', string);
    return cleaned_string;
}



with entry {
    print(remove_punctuation(0));
}
