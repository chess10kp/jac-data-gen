def remove_duplicates(s: str) -> str {
    result = "";
    seen: set = set();
    for char in s {
        if char not in seen {
            result += char;
            seen.add(char);
        }
    }
    return result;
}

with entry {
    print(remove_duplicates("hello"));
}
