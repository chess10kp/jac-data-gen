def count_div_tags(html_elements: Any) -> object {
    count = 0;
    for element in html_elements {
        if (
            ('<div' in element)
            and ('width="400px"' in element)
            and ('background-color="#00FFFF"' in element)
        ) {
            count += 1;
        }
    }
    return count;
}



with entry {
    print(count_div_tags('hello'));
}
