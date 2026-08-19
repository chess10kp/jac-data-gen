def count_div_tags(html_code: Any) -> object {
    count = 0;
    start_tag = "<div";
    end_tag = "</div>";
    start_index = html_code.find(start_tag);
    while (start_index != -1) {
        count += 1;
        end_index = html_code.find(end_tag, start_index) + len(end_tag);
        html_code = html_code[end_index:];
        start_index = html_code.find(start_tag);
    }
    return count;
}



with entry {
    print(count_div_tags('hello'));
}
