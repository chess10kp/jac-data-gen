""" function that converts to lower case and removes stop words """
def format_match_string(string: str, fm_stopwords: set[str]) -> str {
    return ' '.join([word for word in string.lower().split() if word not in fm_stopwords]);
}