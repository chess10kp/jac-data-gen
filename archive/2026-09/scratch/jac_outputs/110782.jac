"""lambda function in pandas to delete sentences in postings with question marks"""
def lambda_delete_question(sentences: list[str]) -> list[str] {
    return [sentence for sentence in sentences if sentence.find('?') == -1];
}