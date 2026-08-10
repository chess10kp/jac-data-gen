"""Match question words with the keywords.
Return True and the matched word if at least one word is matched."""
def match_task(question: str, keywords: list[str]) -> str {
    for word in question.split(" ") {
        for kw in keywords {
            if word == kw {
                return word;
            }
        }
    }
    return "";
}