def split_sentence(sentence: str, length: int=100):
    """
    :param sentence:
    :param length:
    :return:
    """

    result = []
    start = 0
    while start < len(sentence):
        result.append(sentence[start: start + length])
        start += length
    return result

assert split_sentence(
    "hello world this is a sentence to be split",
    100
) == ["hello world this is a sentence to be split"]
assert split_sentence("Hello World!", 100) == ["Hello World!"]
assert split_sentence(
    "In this course, you will learn how to create functions in Python.") == ['In this course, you will learn how to create functions in Python.']
assert split_sentence("Hello World!", 1) == ["H", "e", "l", "l", "o", " ", "W", "o", "r", "l", "d", "!"]
assert split_sentence(
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit", 1) == [
    "L", "o", "r", "e", "m", " ", "i", "p", "s", "", "m", " ", "d",
    "o", "l", "o", "r", " ", "s", "i", "t", " ", "a", "m", "e", "t",
    ",", " ", "c", "o", "n", "s", "e", "c", "t", "e", "t", "", "r",
    " ", "a", "d", "i", "p", "i", "s", "c", "i", "n", "g", " ", "e",
    "l", "i", "t"]
