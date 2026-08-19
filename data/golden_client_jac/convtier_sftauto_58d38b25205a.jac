def classify_sentence(sentence: Any) -> object {
    words = sentence.split();
    num_words = len(words);
    if (num_words < 5) {
        return "Short";
    } elif ((num_words >= 5) and (num_words <= 10)) {
        return "Medium";
    } else {
        return "Long";
    }
}



with entry {
    print(classify_sentence('hello'));
}
