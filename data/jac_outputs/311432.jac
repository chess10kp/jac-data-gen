"""Evaluates the predicted chunk accuracy."""
def eval(predicted: list[list[dict[str, str]]]) -> float {
    word_cnt = 0;
    correct = 0;
    for sentence in predicted {
        for row in sentence {
            word_cnt += 1;
            if row['chunk'] == row['pchunk'] {
                correct += 1;
            }
        }
    }
    return correct / word_cnt;
}