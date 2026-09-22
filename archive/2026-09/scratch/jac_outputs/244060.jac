""" Roughly detokenizes (mainly undoes wordpiece) """
def detokenize(sent: Any) -> object {
    new_sent = [];
    for (i, tok) in enumerate(sent) {
        if tok.startswith("##") {
            new_sent[(len(new_sent) - 1)] = new_sent[(len(new_sent) - 1)] + tok[2:];
        } else {
            new_sent.append(tok);
        }
    }
    return new_sent;
}