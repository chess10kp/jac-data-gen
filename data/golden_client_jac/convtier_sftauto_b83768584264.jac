def generate_paragraph(input_text: Any) -> object {
    sentences = input_text.split('. ');
    sentences = `list(`dict.fromkeys(sentences));
    paragraph = ' '.join(sentences);
    return paragraph;
}



with entry {
    print(generate_paragraph('hello'));
    print(generate_paragraph('Racecar'));
    print(generate_paragraph('abcabc'));
}
