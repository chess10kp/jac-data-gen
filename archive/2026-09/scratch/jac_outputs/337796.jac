"""Return a list of probabilities for word in each model"""
def language_probabilities(word: Any, models: Any) -> object {
    probabilities = `list(
        map(lambda (model: Any) { model.find_word_probability(word)[0]; }, models)
    );
    return probabilities;
}