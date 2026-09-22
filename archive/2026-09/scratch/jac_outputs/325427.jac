"""Generate n-grams of the sentence"""
def generate_multigrams(sentence: str) -> list[str] {
    (tokens, multigrams) = (sentence.split(), []);
    token_length = len(tokens);
    for y in range(token_length) {
        new_sentence = True;
        support_text = "";
        for x in range(y, token_length) {
            if y == 0 and token_length > 2 and x == token_length {
                continue;
            }
            if len(tokens[x]) <= 2 and tokens[x] != tokens[-1] {
                support_text += f" {tokens[x]}";
                continue;
            }
            last = "";
            if x > y and len(multigrams) > 0 and not new_sentence {
                last = multigrams[-1];
            }
            multigrams.append(f"{last}{support_text} {tokens[x]}".strip());
            new_sentence = False;
            support_text = "";
        }
    }
    return multigrams;
}