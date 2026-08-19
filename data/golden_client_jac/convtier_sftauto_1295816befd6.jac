def generate_textbox_html(input_string: Any) -> object {
    textbox_html = f'<input type="text" id="{input_string}">';
    return textbox_html;
}



with entry {
    print(generate_textbox_html('hello'));
    print(generate_textbox_html('Racecar'));
    print(generate_textbox_html('abcabc'));
}
