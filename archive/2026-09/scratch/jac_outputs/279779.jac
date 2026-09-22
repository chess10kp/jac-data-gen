"""Convert numbers in word form to integers."""
def text_to_int(textnum: str) -> int | float {
    units = [
        "zero",
        "one",
        "two",
        "three",
        "four",
        "five",
        "six",
        "seven",
        "eight",
        "nine",
        "ten",
        "eleven",
        "twelve",
        "thirteen",
        "fourteen",
        "fifteen",
        "sixteen",
        "seventeen",
        "eighteen",
        "nineteen"
    ];
    tens = [
        "",
        "",
        "twenty",
        "thirty",
        "forty",
        "fifty",
        "sixty",
        "seventy",
        "eighty",
        "ninety"
    ];
    modifiers = ["", "quarter", "half", "three-quarters"];
    numwords: dict[str, int | float] = {"and": 0, "a": 0};
    for (idx, word) in enumerate(units) {
        numwords[word] = idx;
    }
    for (idx, word) in enumerate(tens) {
        numwords[word] = idx * 10;
    }
    for (idx, word) in enumerate(modifiers) {
        numwords[word] = idx * 0.25;
    }
    current: int | float = 0;
    for word in textnum.split() {
        if word not in numwords {
            raise ValueError("Illegal word: " + word);
        }
        current += numwords[word];
    }
    return current;
}