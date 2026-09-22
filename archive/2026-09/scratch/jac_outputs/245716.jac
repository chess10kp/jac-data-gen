"""
Tokenizes sentence, naively splitting by space only.
This is only for cleaning, a real tokenizer is suppossed to be applied
later in the process.
"""
def Naive_Tokenizer(sentence: str) -> list[str] {
    return sentence.split();
}