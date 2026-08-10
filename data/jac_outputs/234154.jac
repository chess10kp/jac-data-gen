"""Change a text with TEXT[ABC..] into a list with [TEXTA, TEXTB, TEXC, ...
if no bracket is used it just return the a list with the single text
It uses recursivity to allow several [] in the text"""
def expand_brackets(text: str | None) -> list[str] | tuple[None] {
    if text is None {
        return (None,);
    }
    start = text.find("[");
    end = text.find("]");
    if start < 0 or end < 0 {
        return [text];
    }
    text_list: list[str] = [];
    for char in text[start + 1:end] {
        text_list += expand_brackets(text[:start] + char + text[end + 1:]);
    }
    return text_list;
}