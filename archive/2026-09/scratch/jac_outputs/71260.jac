"""returns substring between two given markers"""
def between_markers(text: str, begin: str, end: str) -> str {
    return ''
        if len(text.split(begin)[0]) > len(text.split(end)[0])
            and begin in text
            and end in text
        else text.split(begin)[-1].split(end)[0]
            if begin in text and end in text
            else text.split(begin)[-1]
                if begin in text
                else text.split(end)[0] if end in text else text;
}