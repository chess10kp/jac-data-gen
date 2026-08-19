def extract_urls(strings: Any) -> object {
    urls = [];
    pattern = r"(http[s]?://[^\s]+)";
    for string in strings {
        matches = re.findall(pattern, string);
        urls.extend(matches);
    }
    return urls;
}



with entry {
    print(extract_urls([]));
}
