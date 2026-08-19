def bold_words(html: Any) -> object {
    words = html.split();
    new_html = "";
    for word in words {
        if ('e' not in word) {
            new_html += "<b>" + word + "</b> ";
        } else {
            first_e_index = word.index('e');
            new_html += (
                "<b>" + word[:(first_e_index + 1)] + "</b>" + word[(
                    first_e_index + 1
                ):] + " "
            );
        }
    }
    return new_html.strip();
}



with entry {
    print(bold_words('hello'));
    print(bold_words('Racecar'));
    print(bold_words('abcabc'));
}
