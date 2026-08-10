"""Convert NLTK POS tags to SentiWordNet's POS tags."""
def convert_postag(pos: str) -> str {
    if pos in ['VB', 'VBD', 'VBG', 'VBN', 'VBP', 'VBZ'] {
        return 'v';
    } elif pos in ['JJ', 'JJR', 'JJS'] {
        return 'a';
    } elif pos in ['RB', 'RBR', 'RBS'] {
        return 'r';
    } elif pos in ['NNS', 'NN', 'NNP', 'NNPS'] {
        return 'n';
    } else {
        return '';
    }
}