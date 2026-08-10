"""
    Takes a string with the format lang:probability and returns
    a tuple (lang, probability)
    Args:
        lang_prob: str
    """
def get_lang_probability(lang_prob: Any) -> object {
    (lang, probability) = lang_prob.split(":");
    try {
        probability = float(probability);
    } except Exception as e {
        print("Cound not convert probability to float");
        print(e);
    }
    return (lang, probability);
}